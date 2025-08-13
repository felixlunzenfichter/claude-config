#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const server = new Server(
  {
    name: 'system-tools',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {}
    }
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'tmux',
        description: 'Execute tmux commands for persistent session management',
        inputSchema: {
          type: 'object',
          properties: {
            command: {
              type: 'string',
              description: 'Complete tmux command string (everything after "tmux")'
            }
          },
          required: ['command']
        }
      }
    ]
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  
  switch (name) {
    case 'tmux': {
      const { command } = args;
      
      // Construct complete tmux command
      const fullCommand = `tmux ${command}`;
      
      let stdout = '';
      let stderr = '';
      let exitCode = 0;
      
      try {
        const result = await execAsync(fullCommand);
        stdout = result.stdout || '';
        stderr = result.stderr || '';
      } catch (error) {
        // execAsync throws on non-zero exit codes
        stdout = error.stdout || '';
        stderr = error.stderr || '';
        exitCode = error.code || 1;
      }
      
      const formattedOutput = `STDOUT:${stdout || 'No stdout'}\nSTDERR:${stderr || 'No stderr'}\nEXIT_CODE:${exitCode}`;
      
      return {
        content: [
          {
            type: 'text',
            text: formattedOutput
          }
        ]
      };
    }
    
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
console.error('System Tools MCP Server running on stdio');