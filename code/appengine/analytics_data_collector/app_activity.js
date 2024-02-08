// app_activity.js
const { Storage } = require('@google-cloud/storage');
const DeviceDetector = require('device-detector-js');
const dayjs = require('dayjs');
var utc = require('dayjs/plugin/utc')
dayjs.extend(utc)

const storage = new Storage();
const deviceDetector = new DeviceDetector();
const querystring = require('querystring');


async function collectInappData(req, res) {
    try {
        let body;
        if (req.method === 'POST') {
          body = req.body;
          if (body.activity !== null && typeof body.activity === 'object') {
            body = { 
              ...body,
              ...body.activity
            };
          }
        } else if (req.method === 'GET') {
          const dataParam = req.query.data;
          if (dataParam) {
            body = JSON.parse(querystring.unescape(dataParam));
          } else {
            res.status(400).send('No data parameter found in the request');
            return;
          }
        } else {
          res.status(405).send('Unsupported request method');
          return;
        }
        const data = {
          timestamp: new Date().toISOString().replace('T', ' ').replace('Z', ''),
          event: body.event,
          type: body.type || 'action',
          account_id: body?.identity?.account?.id,
          user_id: body?.identity?.user?.id,
          anon_id: body?.identity?.anon,
          identity_details: body.identity ? {...body.identity} : {},
          event_properties: body.event_properties ? JSON.stringify(body.event_properties) : (body.context ? JSON.stringify(body.context) : ''),
          account_properties: body.account_properties ? {...body.account_properties} : (body.traits ? {...body.traits} : {}),
          user_properties: body.user_properties ? JSON.stringify(body.user_properties) : '',
          labels: body.labels ? JSON.stringify(body.labels) : '',
        };

        if (data.identity_details && data.identity_details.account && data.identity_details.account.created_at && 
          (!data.account_properties || !data.account_properties.created_at)) {
       
           // if 'account_properties' does not exist, initialize it as an empty object
           data.account_properties = data.account_properties || {};
       
           // Transfer the 'created_at' value
           data.account_properties.created_at = data.identity_details.account.created_at;
       
           // Delete 'created_at' from 'identity_details.account'
           delete data.identity_details.account.created_at;
       }
    
        const userAgent = req.get('User-Agent');
        const ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
    
        data.device_details = JSON.stringify({
          ip: ip,
          userAgent: userAgent,
          device: deviceDetector.parse(userAgent),
        });
    
        const valid_log =
          ['action', 'identify', 'email', 'revenue'].includes(data.type) &&
          (data.account_id || data.user_id || data.anon_id);
    
        const folder = data.account_id || data.user_id ? 'inapp_activity' : 'website_activity';
        const day_folder = dayjs().utc().format('YYYYMMDD'); // Define the day folder as current day in format YYYYMMDD
    
        if (valid_log) {
          data.identity_details = JSON.stringify(data.identity_details);
          data.account_properties = JSON.stringify(data.account_properties);
          
          const bucketName = '__BUCKET_NAME__';
          const fileName = `${folder}/${day_folder}/${Date.now()}.ndjson`;
          const fileContents = JSON.stringify(data) + '\n';
    
          const file = storage.bucket(bucketName).file(fileName);
          await file.save(fileContents, { resumable: false });
    
          res.status(200).send('Saved');
        } else {
          console.log(body);
          res.status(500).send('Not saved');
        }
      } catch (error) {
        console.error(error);
        res.status(500).send('Internal Server Error');
      }
}

module.exports = collectInappData;
