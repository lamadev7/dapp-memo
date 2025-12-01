import { Router } from 'express';
const { uploader } = require("../../../configs/index");

const router = Router();
const { createElectionController } = require("../controllers/index");

router.post('/admin/createElection', uploader.single("image"), createElectionController.createElection);

module.exports = router;