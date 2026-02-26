import { Express, Request, Response } from "express";
import { Connection, Model } from "mongoose";

interface RouteDependencies {
  Task: Model<any>;
  mongoConnection: Connection;
}

export const registerRequestHandlers = (
  app: Express,
  { Task, mongoConnection }: RouteDependencies,
) => {
  app.get("/health", (req: Request, res: Response) => {
    res.json({
      status: "OK",
      timestamp: new Date().toISOString(),
      database: mongoConnection.readyState === 1 ? "Connected" : "Disconnected",
    });
  });

  app.get("/api/tasks", async (req: Request, res: Response) => {
    try {
      const tasks = await Task.find().sort({ createdAt: -1 });
      res.json({
        success: true,
        count: tasks.length,
        data: tasks,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  });

  app.post("/api/tasks", async (req: Request, res: Response) => {
    try {
      const { title } = req.body;

      if (!title) {
        return res.status(400).json({
          success: false,
          error: "Title is required",
        });
      }

      const task = await Task.create({ title });
      res.status(201).json({
        success: true,
        data: task,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  });

  app.put("/api/tasks/:id", async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const task = await Task.findByIdAndUpdate(id, req.body, {
        new: true,
        runValidators: true,
      });

      if (!task) {
        return res.status(404).json({
          success: false,
          error: "Task not found",
        });
      }

      res.json({
        success: true,
        data: task,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  });

  app.delete("/api/tasks/:id", async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const task = await Task.findByIdAndDelete(id);

      if (!task) {
        return res.status(404).json({
          success: false,
          error: "Task not found",
        });
      }

      res.json({
        success: true,
        message: "Task deleted successfully",
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  });

  app.get("/", (req: Request, res: Response) => {
    res.json({
      message:
        "🐳 Welcome to Docker Node.js + MongoDB API (TypeScript), Changes - 3",
      endpoints: {
        health: "GET /health",
        tasks: {
          getAll: "GET /api/tasks",
          create: "POST /api/tasks",
          update: "PUT /api/tasks/:id",
          delete: "DELETE /api/tasks/:id",
        },
      },
    });
  });
};
