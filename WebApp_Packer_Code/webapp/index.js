import express from "express";
import bodyParser from "body-parser";
import readline from 'readline';
import usersRoutes from "./routes/users_r.js";
import mysql from 'mysql2';
import Sequelize from 'sequelize';
import bootstrap from './bootstrap.js';
import winston from 'winston';
import path from 'path';
import StatsD from 'node-statsd';

export const client = new StatsD();

// Function to create custom metric for API call
export function logAPICall(apiName) {
  const metricName = `api.${apiName}`;
  client.increment(metricName);
}

// setting up the logger function
const { combine, timestamp, printf } = winston.format;

const customFormat = printf(({ level, message, timestamp }) => {
  return `${timestamp} ${level}: ${message}`;
});

export const logger = winston.createLogger({
  level: 'info',
  format: combine(
    timestamp(),
    customFormat
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: '/home/ec2-user/WebApp/webapp/app.log' })
  ]
});

const logPath = path.join(new URL('app.log', import.meta.url).pathname);
logger.info(`Log file path: ${logPath}`);

const dbHost = process.env.DBHOST;
const dbUser = process.env.DBUSER;
const dbPass = process.env.DBPASS;
const database = process.env.DATABASE;
const port = process.env.PORT;
const dbPort = process.env.DBPORT;
const bucketName = process.env.BUCKETNAME;

//Database Connection
export const db = mysql.createConnection({
  host: dbHost,
  user: dbUser,
  password: dbPass,
  database: database
});
db.connect(function(err) {
  if (err) {
    logger.error('Error connecting to MySQL database:', err);
    throw err;
  }
  logger.info('Connected to MySQL database');
});

export const sequelize = new Sequelize(database, dbUser, dbPass, {
host: dbHost,//'root.crxkjte00zsr.us-east-1.rds.amazonaws.com',
dialect: 'mysql',
});
// Initialising the application
const app = express();

//Setting the port no to listen on any environment variable named 'Port', default port 3000 if not found in env variables
const PORT = process.env.PORT || 3000;

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

//Initialising the readline
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });  
  
//Setting up API endpoints
app.use("/v2", usersRoutes);

app.get("/health", (req, res) => {
  logger.info("Healthz API called");
  res.send("Welcome to the Users API!");
});


//Application to start listening on any available port

app.listen(PORT, () => {
  logger.info("Application listening on port : 3000")
  //console.log(`App listening on port ${PORT}`);
});
//home();

bootstrap(sequelize).then(() => {
  logger.info('Database Bootstrapped successfully');
  home();
  })
  .catch((error) => {
  logger.error('Error Bootstrapping database:', error);
  });

// Home function that first runs when program starts

function home() {
  logger.info("Application Started")
  //console.log(process.env.AWS_PRIVATE)
}

  