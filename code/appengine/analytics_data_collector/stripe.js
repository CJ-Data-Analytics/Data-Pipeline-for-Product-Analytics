// stripe.js
const { Storage } = require('@google-cloud/storage');
const dayjs = require('dayjs');
var utc = require('dayjs/plugin/utc')
dayjs.extend(utc)

const storage = new Storage();

async function collectStripeData(req, res) {
    try {
        let body;
        if (req.method === 'POST') {
            const data = req.body;
            data.data = JSON.stringify(data.data);
            data.request = JSON.stringify(data.request);

            const bucketName = '__BUCKET_NAME__';
            const day_folder = dayjs().utc().format('YYYYMMDD'); // Define the day folder as current day in format YYYYMMDD
            
            const fileName = `stripe/${day_folder}/${Date.now()}.ndjson`;
            const fileContents = JSON.stringify(data) + '\n';
        
            const file = storage.bucket(bucketName).file(fileName);
            await file.save(fileContents, { resumable: false });
        
            res.status(200).send('Saved');
          
        } else {
            console.log(body);
            res.status(500).send('Not saved');
            return;
        }
      } catch (error) {
        console.error(error);
        res.status(500).send('Internal Server Error');
      }
}

module.exports = collectStripeData;
