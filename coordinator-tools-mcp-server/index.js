#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';

const execAsync = promisify(exec);

const WORKER_REGISTRY_FILE = '/tmp/claude_workers.jsonl';

async function ensureRegistryFile() {
  try {
    await fs.access(WORKER_REGISTRY_FILE);
  } catch {
    await fs.writeFile(WORKER_REGISTRY_FILE, '');
  }
}

async function addWorkerToRegistry(name, paneId) {
  const entry = JSON.stringify({ name, paneId }) + '\n';
  await fs.appendFile(WORKER_REGISTRY_FILE, entry);
}

async function removeWorkerFromRegistry(paneId) {
  try {
    const content = await fs.readFile(WORKER_REGISTRY_FILE, 'utf8');
    const lines = content.split('\n').filter(line => {
      if (!line.trim()) return false;
      try {
        const data = JSON.parse(line);
        return data.paneId !== paneId;
      } catch {
        return false;
      }
    });
    await fs.writeFile(WORKER_REGISTRY_FILE, lines.join('\n') + (lines.length > 0 ? '\n' : ''));
  } catch (error) {
    console.error('Error removing worker from registry:', error);
  }
}

async function getWorkers() {
  try {
    const content = await fs.readFile(WORKER_REGISTRY_FILE, 'utf8');
    return content.split('\n').filter(line => line.trim()).map(line => {
      try {
        return JSON.parse(line);
      } catch {
        return null;
      }
    }).filter(Boolean);
  } catch {
    return [];
  }
}

async function getPaneIdByName(workerName) {
  const workers = await getWorkers();
  const worker = workers.find(w => w.name === workerName);
  if (!worker) {
    throw new Error(`Worker '${workerName}' not found`);
  }
  return worker.paneId;
}

const server = new Server(
  {
    name: 'coordinator-tools',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'spawn_worker',
        description: 'Creates a new Claude worker instance in a tmux pane',
        inputSchema: {
          type: 'object',
          properties: {
            name: {
              type: 'string',
              description: 'Name identifier for the worker (e.g., BACKEND_SERVER_UPDATE_WORKER)'
            },
            work_dir: {
              type: 'string',
              description: 'Working directory path for the worker'
            },
            start_message: {
              type: 'string',
              description: 'Initial message to send to the worker (optional)'
            }
          },
          required: ['name', 'work_dir']
        }
      },
      {
        name: 'send_to_worker',
        description: 'Sends a command or message to an existing worker',
        inputSchema: {
          type: 'object',
          properties: {
            worker_name: {
              type: 'string',
              description: 'The name of the worker (e.g., BACKEND_UPDATE_WORKER)'
            },
            message: {
              type: 'string',
              description: 'The message or command to send'
            }
          },
          required: ['worker_name', 'message']
        }
      },
      {
        name: 'kill_worker',
        description: 'Terminates a worker instance and removes it from tracking',
        inputSchema: {
          type: 'object',
          properties: {
            worker_name: {
              type: 'string',
              description: 'The name of the worker to terminate'
            }
          },
          required: ['worker_name']
        }
      },
      {
        name: 'list_workers',
        description: 'Shows all active workers and their status',
        inputSchema: {
          type: 'object',
          properties: {}
        }
      },
      {
        name: 'monitor_worker',
        description: 'Shows real-time output from a worker pane',
        inputSchema: {
          type: 'object',
          properties: {
            worker_name: {
              type: 'string',
              description: 'The name of the worker to monitor'
            },
            lines: {
              type: 'number',
              description: 'Number of lines to capture (default: all)',
              default: -1
            }
          },
          required: ['worker_name']
        }
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'spawn_worker': {
        const { name: workerName, work_dir: workDir, start_message: startMessage } = args;
        
        await ensureRegistryFile();
        
        const cmd = `tmux split-window -h -P -F "#{pane_id}" "cd ${workDir} && claude --model opus --dangerously-skip-permissions"`;
        const { stdout } = await execAsync(cmd);
        const paneId = stdout.trim();
        
        await execAsync('tmux select-layout even-horizontal');
        
        await addWorkerToRegistry(workerName, paneId);
        
        // Wait for Claude to initialize
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Build message
        let fullMessage = `General instructions: Please read /Users/felixlunzenfichter/Documents/ClaudeCode/claude-config/CLAUDE_WORKER.md and confirm your understanding.\nSpecific task: ${startMessage || 'Ready for commands.'}`;
        
        // Send the message
        await execAsync(`tmux send-keys -t "${paneId}" "${fullMessage}"`);
        
        // Wait 1 second before pressing Enter to give time for the message to process
        await new Promise(resolve => setTimeout(resolve, 1000));
        await execAsync(`tmux send-keys -t "${paneId}" Enter`);
        
        return {
          content: [
            {
              type: 'text',
              text: `Worker ${workerName} spawned successfully`
            }
          ],
          data: { 
            workerName
          }
        };
      }
      
      case 'send_to_worker': {
        const { worker_name: workerName, message } = args;
        
        const paneId = await getPaneIdByName(workerName);
        
        await execAsync(`tmux send-keys -t "${paneId}" "${message}"`);
        await new Promise(resolve => setTimeout(resolve, 1000));
        await execAsync(`tmux send-keys -t "${paneId}" Enter`);
        
        return {
          content: [
            {
              type: 'text',
              text: `Message sent to worker ${workerName}`
            }
          ]
        };
      }
      
      case 'kill_worker': {
        const { worker_name: workerName } = args;
        
        const paneId = await getPaneIdByName(workerName);
        
        await execAsync(`tmux kill-pane -t "${paneId}"`);
        await execAsync('tmux select-layout even-horizontal');
        await removeWorkerFromRegistry(paneId);
        
        return {
          content: [
            {
              type: 'text',
              text: `Worker ${workerName} terminated`
            }
          ]
        };
      }
      
      case 'list_workers': {
        const workers = await getWorkers();
        const paneList = await execAsync('tmux list-panes -F "#{pane_id} #{pane_active} #{pane_current_command}"');
        const panes = paneList.stdout.split('\n').filter(line => line.trim());
        
        const workerInfo = workers.map(worker => {
          const paneInfo = panes.find(p => p.startsWith(worker.paneId));
          return {
            ...worker,
            active: paneInfo ? paneInfo.includes(' 1 ') : false,
            command: paneInfo ? paneInfo.split(' ').slice(2).join(' ') : 'unknown'
          };
        });
        
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(workerInfo, null, 2)
            }
          ]
        };
      }
      
      case 'monitor_worker': {
        const { worker_name: workerName, lines = -1 } = args;
        
        const paneId = await getPaneIdByName(workerName);
        
        const cmd = lines === -1 
          ? `tmux capture-pane -t "${paneId}" -p`
          : `tmux capture-pane -t "${paneId}" -p | tail -${lines}`;
        
        const { stdout } = await execAsync(cmd);
        
        return {
          content: [
            {
              type: 'text',
              text: stdout
            }
          ]
        };
      }
      
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error.message}`
        }
      ],
      isError: true
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('MCP Worker Server running on stdio');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});