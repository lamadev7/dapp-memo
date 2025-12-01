import fs from 'fs';
import { Request, Response } from 'express';
import path from 'path';

const { UPLOAD_FOLDER_PATH } = require("../../../constants/index");
const { uploadFileToFirebaseStorage } = require("../../../domain/services/index");

const uploadFile = async (req: Request, res: Response) => {
  try {
    const arr = req?.files as Express.Multer.File[];

    const promises = arr.map((d: any) => {
      const path = uploadFileToFirebaseStorage(d.filename);
      return path;
    });

    const imgHostedURL = await Promise.all(promises);

    res.status(200).send({
      message: "File uploaded successfully",
      url: imgHostedURL,
      statusCode: 200
    });
  } catch (error) {
    console.error(error)
    res.status(500).send({
      message: "Internal Server Error.",
      url: null,
      statusCode: 500
    });
  }
};

const getFile = async (req: Request, res: Response) => {
  try {
    const { filename } = req.params;
    const safeName = path.basename(filename);
    const filePath = path.join(UPLOAD_FOLDER_PATH, safeName);
    
    // Determine content type based on extension
    const ext = path.extname(filename).toLowerCase();
    const contentTypes: { [key: string]: string } = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp'
    };

    const contentType = contentTypes[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, data) => {
      if (err) {
        return res.status(404).send({
          message: "File not found.",
          statusCode: 404
        });
      }
      res.setHeader('Content-Type', contentType);
      res.status(200).send(data);
    });

  } catch (error) {
    console.error(error);
    res.status(500).send({
      message: "Internal Server Error.",
      statusCode: 500
    });
  }
};

module.exports = {
  uploadFile,
  getFile,
}