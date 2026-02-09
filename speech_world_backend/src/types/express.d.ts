// Custom Express types for file upload support
import { Request } from 'express';

// Define the file object interface
export interface UploadedFile {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  size: number;
  destination: string;
  filename: string;
  path: string;
  buffer?: Buffer;
}

// Extend Express Request interface to include file properties
declare global {
  namespace Express {
    interface Request {
      file?: UploadedFile;
      files?: UploadedFile[] | { [fieldname: string]: UploadedFile[] };
    }
  }
}

export {};