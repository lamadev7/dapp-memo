const startElectionCronJob = require("./cron/election-cron");


const uploadFileToFirebaseStorage =  (fileName: string) => {
  return `${process.env.BASE_URL}/media/${fileName}`;  
}

module.exports = {
 startElectionCronJob,
 uploadFileToFirebaseStorage,
}
