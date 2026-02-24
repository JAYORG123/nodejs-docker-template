// Import required modules with TypeScript types
import express from "express";
import mongoose, { Schema, Document } from "mongoose";
import dotenv from "dotenv";
import { registerRequestHandlers } from "./requestHandlers";

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();

// Middleware to parse JSON requests
app.use(express.json());

// Environment variables with default values
const PORT: number = parseInt(process.env.PORT || "3000", 10);
const MONGO_URI: string =
  process.env.MONGO_URI || "mongodb://localhost:27017/dockerapp";

// TypeScript interface for Task document
interface ITask extends Document {
  title: string;
  completed: boolean;
  createdAt: Date;
}

// Mongoose Schema for Task
const TaskSchema: Schema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  completed: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Create Task model with TypeScript interface
const Task = mongoose.model<ITask>("Task", TaskSchema);

// Connect to MongoDB
mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log("✅ Successfully connected to MongoDB");
    console.log(`📦 Database: ${MONGO_URI}`);
  })
  .catch((error: Error) => {
    console.error("❌ MongoDB connection error:", error.message);
    // In production, you might want to exit the process
    // process.exit(1);
  });

registerRequestHandlers(app, {
  Task,
  mongoConnection: mongoose.connection,
});

// Start the server and store the server instance
const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`🌍 Access the API at: http://localhost:${PORT}`);
});

// Graceful shutdown handler
const gracefulShutdown = async (signal: string) => {
  console.log(`\n👋 ${signal} signal received: starting graceful shutdown`);

  // Stop accepting new connections
  server.close(async (err) => {
    if (err) {
      console.error("❌ Error closing server:", err);
      process.exit(1);
    }

    console.log("🛑 HTTP server closed (no longer accepting connections)");

    try {
      // Close database connection
      await mongoose.connection.close();
      console.log("📦 MongoDB connection closed");

      console.log("✅ Graceful shutdown completed");
      process.exit(0);
    } catch (error) {
      console.error("❌ Error during shutdown:", error);
      process.exit(1);
    }
  });

  // Force shutdown after timeout if graceful shutdown takes too long
  setTimeout(() => {
    console.error("⚠️  Graceful shutdown timed out, forcing exit...");
    process.exit(1);
  }, 30000); // 30 seconds timeout
};

// Listen for termination signals
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT")); // Handle Ctrl+C
