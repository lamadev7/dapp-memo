const multer = require("multer");
const { UPLOAD_FOLDER_PATH } = require("../src/constants/index");

const storage = multer.diskStorage({
  destination: (req: any, file: any, cb: any) => {
    cb(null, UPLOAD_FOLDER_PATH);
  },
  filename: (req: any, file: any, cb: any) => {
    const originalFileName = file.originalname;
    const fileExt = originalFileName.substring(originalFileName.lastIndexOf('.'));
    const baseName = originalFileName.substring(0, originalFileName.lastIndexOf('.'));
    const safeBaseName = baseName.replace(/[^a-zA-Z0-9-_]/g, '_');
    const fileName = `${safeBaseName}-${Date.now()}${fileExt}`;
    cb(null, fileName);
  }
});

const uploader = multer({ storage: storage });

module.exports = uploader;
