const cron = require("node-cron");
const { pusherInstance } = require("../../../../configs");


const startJob = (startDate: string, endDate: string) => {
  // convert date form
  const startDateFormat = new Date(startDate);
  const endDateFormat = new Date(endDate);

  const scheduleStartDateString = `${startDateFormat.getMinutes()} ${startDateFormat.getHours()} ${startDateFormat.getDate()} ${startDateFormat.getMonth() + 1} ${startDateFormat.getDay()}`;
  const scheduleEndDateString = `${endDateFormat.getMinutes()} ${endDateFormat.getHours()} ${endDateFormat.getDate()} ${endDateFormat.getMonth() + 1} ${endDateFormat.getDay()}`;

  console.log(scheduleStartDateString, scheduleEndDateString)

  // start listening to the start date events
  cron.schedule(scheduleStartDateString, () => {
    console.log("startdate triggered");

    try {
      pusherInstance.trigger("election", "start-election-event", {});
    } catch (error) {
      console.error(error);
    }
  });

  // start listening to the start date events
  cron.schedule(scheduleEndDateString, () => {
    console.log("endate triggered");
    try {
      pusherInstance.trigger("election", "end-election-event", {});
    } catch (error) {
      console.error(error);
    }
  });
}

module.exports = startJob;