const startElectionCronJob = require("./cron/election-cron");


const uploadFileToFirebaseStorage =  (folderPath: string, fileName: string, collectionName: string) => {
  return `${folderPath}/${fileName}`;  
}

module.exports = {
 startElectionCronJob,
 uploadFileToFirebaseStorage,
}
