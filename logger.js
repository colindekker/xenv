
const winston = require('winston');
var LOGS = path.resolve(__dirname, 'logs');
var CONFIG = path.resolve(__dirname, 'config');
logger.warn('Starting config.');
var logger = new (winston.Logger)({
  "transports": [
    new winston.transports.Console(),
    new winston.transports.File(
      { "filename": path.join(LOGS, 'all-logs.log') }
    )
  ],
  exceptionHandlers: [
    new winston.transports.File({
      filename: path.join(LOGS, 'exceptions.log')
    })
  ]
});
