import React, { Component } from "react";
import { Redirect } from 'react-router-dom';

// Components
import Header from "../../layout/Header";
import Footer from "../../components/Footer";


import style from "./style.module.scss";


function getSearchParams() {
  return window.location.search
    .slice(1)
    .split('&')
    .reduce((acc, n) => {
      const [key, value] = n.split('=');
      acc[key] = decodeURIComponent(value);
      return acc;
    }, {});
}

function renderDate(date) {
  return new Date(date).toLocaleString();
}

class ThankYou extends Component {
  render() {

    const params = getSearchParams();

    if (!params.assigned_to) {
      return <Redirect to="/" />;
    }

    return (
      <div className={style.home}>
        <Header />
        <div className={style.content}>

          <h4>Assigned to</h4>
          <p>{params.assigned_to}</p>

          <h4>Event Name</h4>
          <p>{params.event_type_name}</p>

          <h4>Start Time</h4>
          <p>{renderDate(params.event_start_time)}</p>

          <h4>End Time</h4>
          <p>{renderDate(params.event_end_time)}</p>

          <h4>Your Name</h4>
          <p>{params.invitee_full_name}</p>

          <h4>Your Email</h4>
          <p>{params.invitee_email}</p>

        </div>
        <Footer />
      </div>
    );
  }
}

export default ThankYou;
