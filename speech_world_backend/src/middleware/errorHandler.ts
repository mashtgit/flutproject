import { NextFunction, Request, Response } from 'express';
import { logger } from '../utils/logger.js';

// Custom error class
export class AppError extends Error {
  public statusCode: number;
  public isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

// Async error handler wrapper
export const asyncHandler = (fn: Function) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Global error handler middleware
export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  let error = { ...err };
  error.message = err.message;

  // Log error
  logger.error(`${err.message} - ${req.method} ${req.path} - ${req.ip}`);

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    const message = 'Resource not found';
    error = new AppError(message, 404);
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const message = 'Duplicate field value entered';
    error = new AppError(message, 400);
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map((val: any) => val.message).join(', ');
    error = new AppError(message, 400);
  }

  // Firebase Auth errors
  if (err.code && err.code.startsWith('auth/')) {
    let message = 'Authentication failed';
    
    switch (err.code) {
      case 'auth/invalid-token':
        message = 'Invalid or expired token';
        break;
      case 'auth/user-not-found':
        message = 'User not found';
        break;
      case 'auth/invalid-argument':
        message = 'Invalid request argument';
        break;
      case 'auth/missing-argument':
        message = 'Missing required argument';
        break;
      default:
        message = err.message || 'Authentication error';
    }
    
    error = new AppError(message, 401);
  }

  // Firebase Firestore errors
  if (err.code && err.code.startsWith('firestore/')) {
    let message = 'Database operation failed';
    
    switch (err.code) {
      case 'firestore/permission-denied':
        message = 'Permission denied';
        error = new AppError(message, 403);
        break;
      case 'firestore/not-found':
        message = 'Resource not found';
        error = new AppError(message, 404);
        break;
      case 'firestore/already-exists':
        message = 'Resource already exists';
        error = new AppError(message, 409);
        break;
      default:
        message = err.message || 'Database error';
        error = new AppError(message, 500);
    }
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    const message = 'Invalid token';
    error = new AppError(message, 401);
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token expired';
    error = new AppError(message, 401);
  }

  // Joi validation errors
  if (err.isJoi) {
    const message = err.details.map((detail: any) => detail.message).join(', ');
    error = new AppError(message, 400);
  }

  // Default error
  const statusCode = error.statusCode || 500;
  const message = error.message || 'Internal Server Error';

  // Don't send stack trace in production
  const stack = process.env.NODE_ENV === 'production' ? undefined : err.stack;

  res.status(statusCode).json({
    success: false,
    error: {
      message,
      stack,
      timestamp: new Date().toISOString(),
      path: req.path,
    },
  });
};

// 404 handler
export const notFound = (req: Request, res: Response, next: NextFunction) => {
  const error = new AppError(`Route ${req.originalUrl} not found`, 404);
  next(error);
};