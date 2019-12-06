import React, { useState, useRef } from "react";

// Components
import Header from "../../layout/Header";
import Footer from "../../components/Footer";

import style from "./style.module.scss";


// TODO: Move to config
const FORM_URL = 'https://api.tranzmt.it/v1/ambassador';
// const FORM_URL = 'https://safewrd.app/api/form';
// const FORM_URL = 'http://localhost:5000/api/form';
// const FORM_URL = 'http://159.203.169.170/v1/ambassador';
// TODO: Use Johnny
const CALENDLY_URL = 'https://calendly.com/whats-your-safewrd/ambassador-vip-screening';


const Input = (props) => {
  return <input {...props} onChange={e => props.onValue(e.target.value)} />;
};

const Row = (props) => {
  return <div className={style.row} {...props}>{props.children}</div>;
};


/**
 * Turn an object into a query string
 * @param {object} data 
 */
function toQueryString(data) {
  return '?' + Object.keys(data).map(key => `${key}=${data[key]}`).join('&');
}

/**
 * Triggers the Calendly Popup
 * @param {object} data 
 * @param {string} data.firstName
 * @param {string} data.lastName
 * @param {string} data.phone
 * @param {string} data.email
 */
function popCalendly({ firstName, lastName, phone, email }) {
  const payload = {
    name: firstName + ' ' + lastName,
    email,
    phone,
  };
  const url = CALENDLY_URL + toQueryString(payload);
  window.Calendly.initPopupWidget({ url });
  return false;
}


async function imageToDataUrl(input) {
  if (input && input.files && input.files[0]) {
    return new Promise((ok, fail) => {
      var reader = new FileReader();
      reader.onload = e => ok(e.target.result);
      reader.onerror = fail;
      reader.readAsDataURL(input.files[0]);
    });
  }
  return null;
}

export default () => {

  const [loading, setLoading] = useState(false);
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [file, setFile] = useState('');
  const [formEl, setFormEl] = useState(null);

  const inputRef = useRef(null);

  function formIsInvalid() {

    const values = {
      firstName,
      lastName,
      phone,
      email,
    };

    const props = {
      firstName: 'your first name',
      lastName: 'your last name',
      phone: 'your phone number',
      email: 'your email address',
    };

    for (const key in props) {
      if (!values[key]) {
        alert(`Please enter ${props[key]}`);
        return true;
      }
    }

    return false;
  }

  function resetForm() {
    setFirstName('');
    setLastName('');
    setPhone('');
    setEmail('');
    setFile('');
  }

  async function submit(e) {
    try {
      if (e) {
        e.preventDefault();
      }

      if (loading) return;
      setLoading(true);

      if (formIsInvalid()) {
        setLoading(false);
        return;
      }

      const photo = await imageToDataUrl(inputRef.current);

      const resp = await fetch(FORM_URL, {
        method: 'post',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          firstName,
          lastName,
          phone,
          email,
          photo,
        }),
      }).then(r => r.json());

      if (resp.Error) {
        alert(resp.Message);
        setLoading(false);
        return;
      }

      popCalendly({
        firstName,
        lastName,
        email,
        phone,
      });

      // TODO: Re-enable
      setTimeout(resetForm, 3000);

    } catch (e) {
      console.warn(e);
      alert(`Something went wrong. Please try again later.`);
    }

    setLoading(false);
  }

  return (
    <div className={style.contact}>
      <Header />
      <div className={style.content}>

        <h1>Become a VIP</h1>

        <form ref={setFormEl} onSubmit={submit}>
          <Row>
            <label>
              First Name
            <Input name="firstName" value={firstName} onValue={setFirstName} />
            </label>

            <label>
              Last Name
            <Input name="lastName" value={lastName} onValue={setLastName} />
            </label>
          </Row>

          <label>
            Phone
          <Input name="phone" type="tel" value={phone} onValue={setPhone} />
          </label>

          <label>
            Email
          <Input name="email" type="email" value={email} onValue={setEmail} />
          </label>

          <label htmlFor="file">
            Photo
          </label>

          <div className={style.fileWrapper}>
            {file && <button onClick={() => setFile(null)}>Remove File</button>}
            <input ref={inputRef} name="file" id="file" type="file" value={file} onChange={e => setFile(e.target.value)} />
          </div>

          <button type="submit" disabled={loading}>Submit</button>

        </form>
      </div>
      <Footer/>
    </div>
  );
}

console.log(style);
