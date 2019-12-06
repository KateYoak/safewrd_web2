// import { NowRequest, NowResponse } from '@now/node';
import formidable from 'formidable';
import fs from 'fs';
import axios from 'axios';
import FormstackAPI from 'formstack-web-api-node';

// TODO: Change to prod
const BACKEND_URL_DEV = 'http://159.203.169.170/v1/ambassador';
const BACKEND_URL = BACKEND_URL_DEV;
// const FORMSTACK_TOKEN = process.env.FORMSTACK_TOKEN;
// const FORM_ID = 3661274;

// const formstack = new FormstackAPI(FORMSTACK_TOKEN);


function np(fn) {
  return new Promise((ok, fail) => fn((err, res) => err ? fail(err) : ok(res)));
}

export default async (req, res) => {

  res.setHeader("Access-Control-Allow-Origin", "*"); // update to match the domain you will make the request from
  res.setHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS, POST");

  if (req.method === 'OPTIONS') {
    return res.json({ message: 'Success' });
  }

  // const form = await getForm(req);
  console.log(req.body);

  // TODO: Remove this line; it's only for testing
  // res.json({ message: 'OK' });
  res.json(await postForm(form));
}


/**
 * @typedef {object} Form
 * @property {string} firstName
 * @property {string} lastName
 * @property {string} phone
 * @property {string} email
 * @property {string} file
 */


/**
 * Posts the form to the backend
 * @param {*} form 
 */
async function postForm(form) {
  // TODO: See if this keeps the image readable
  // return np(cb => formstack.submitForm(FORM_ID, data, cb));

  const { data } = await axios({
    url: BACKEND_URL,
    method: 'post',
    headers: { 'Content-Type': 'application/json' },
    data: form,
  });

  return data;
}


async function getForm(req, format = 'base64') {
  const { fields, files } = await parse(req);
  const data = await np(cb => fs.readFile(files.file.path, format, cb));
  fields.file = data;
  return fields;
}

async function parse(req) {
  return new Promise((ok, fail) => {
    var form = new formidable.IncomingForm();

    form.parse(req, function (err, fields, files) {
      if (err) {
        return fail(err);
      }
      ok({ fields, files });
    });
  });
}