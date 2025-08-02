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
              description: 'The tmux command to execute'
            },
            session_name: {
              type: 'string',
              description: 'Session name (required for all commands, even global ones like list-sessions)'
            }
          },
          required: ['command', 'session_name']
        }
      }
    ]
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  
  switch (name) {
    case 'tmux': {
      const { command, session_name: sessionName } = args;
      
      // Error if command contains tmux or -t (redundant with function purpose and session_name parameter)
      if (command.startsWith('tmux')) {
        throw new Error('Command should not start with "tmux". Just pass the tmux subcommand.');
      }
      if (command.includes('-t ')) {
        throw new Error('Command should not contain -t flag. Use session_name parameter instead.');
      }
      
      // Always construct full tmux command with session target
      const fullCommand = `tmux ${command} -t ${sessionName}`;
      
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
        exitCode = error.code;
      }
      
      const formattedOutput = `STDOUT:${stdout || 'No stdout'}\nSTDERR:${stderr || 'No stderr'}`;
      
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