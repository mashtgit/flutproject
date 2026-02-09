import { NextFunction, Request, Response } from 'express';
import { AppError } from './errorHandler.js';

// Validation middleware factory
export const validate = (schema: any) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const { error } = schema.validate(req.body, {
      abortEarly: false,
      allowUnknown: false,
      stripUnknown: true,
    });

    if (error) {
      const errorMessage = error.details.map((detail: any) => detail.message).join(', ');
      return next(new AppError(`Validation error: ${errorMessage}`, 400));
    }

    next();
  };
};

// Query validation middleware
export const validateQuery = (schema: any) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const { error } = schema.validate(req.query, {
      abortEarly: false,
      allowUnknown: false,
      stripUnknown: true,
    });

    if (error) {
      const errorMessage = error.details.map((detail: any) => detail.message).join(', ');
      return next(new AppError(`Query validation error: ${errorMessage}`, 400));
    }

    next();
  };
};

// Params validation middleware
export const validateParams = (schema: any) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const { error } = schema.validate(req.params, {
      abortEarly: false,
      allowUnknown: false,
      stripUnknown: true,
    });

    if (error) {
      const errorMessage = error.details.map((detail: any) => detail.message).join(', ');
      return next(new AppError(`Params validation error: ${errorMessage}`, 400));
    }

    next();
  };
};

// File upload validation middleware
export const validateFile = (options: {
  maxSize?: number;
  allowedTypes?: string[];
  required?: boolean;
} = {}) => {
  const {
    maxSize = 5 * 1024 * 1024, // 5MB default
    allowedTypes = ['image/jpeg', 'image/png', 'image/gif'],
    required = false,
  } = options;

  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.file && required) {
      return next(new AppError('File is required', 400));
    }

    if (!req.file) {
      return next();
    }

    // Check file size
    if (req.file.size > maxSize) {
      return next(new AppError(`File size too large. Maximum size is ${maxSize / 1024 / 1024}MB`, 400));
    }

    // Check file type
    if (!allowedTypes.includes(req.file.mimetype)) {
      return next(new AppError(`Invalid file type. Allowed types: ${allowedTypes.join(', ')}`, 400));
    }

    next();
  };
};