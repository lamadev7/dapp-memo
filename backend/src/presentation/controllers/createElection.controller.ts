import { Request, Response } from 'express';

const { electionModel } = require("../../infrastructure/models/index.model");
const { startElectionCronJob } = require("../../domain/services/index");
const { uploadFileToFirebaseStorage } = require("../../domain/services/index");

const createElection = async (req: Request, res: Response) => {
 try {
  const { title, description, startTime, startDate, endTime, endDate } = req.body;

  const response = await new electionModel({
   title, description,
   startDate: startTime ?? startDate, 
   endDate: endTime,
   createdAt: Date.now()
  }).save();

  // assign date listener job to cron
  startElectionCronJob(startTime ?? startDate, endTime ?? endDate);

  const hostedUrl = uploadFileToFirebaseStorage(req.file?.filename ?? '');
  
  res.status(200).send({
   message: "Election registered successfully",
   statusCode: 200,
   data: {...response?._doc ?? {}, bannerImage: hostedUrl}
  });

 } catch (error) {
  console.error('createElection controller error', error)
  res.status(500).send({
   message: "Internal Server Error.",
   statusCode: 500
  });
 }
};

module.exports = {
 createElection
}