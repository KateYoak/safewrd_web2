import React, { Component } from "react";

// Components
import Header from "../../layout/Header";
import Footer from "../../components/Footer";

import style from "./style.module.scss";

class Contact extends Component {
  render() {
    return (
      <div className={style.contact}>
        <Header />
        <div className={style.content}>

          <h1>Contact Us</h1>

          <a href="mailto:info@safewrd.app" rel="noreferrer noopener" target="_blank">
            <p>info@safewrd.app</p>
          </a>
          <a href="tel:+12144848265" rel="noreferrer noopener" target="_blank">
            <p>(214) 484-8265</p>
          </a>

          <OfficeMap />

        </div>

        <Footer />
      </div>
    );
  }
}

function OfficeMap() {
  return (
    <div class={style.mapouter}>
      <iframe
        class={style.map}
        title="Office Map"
        id="gmap_canvas"
        src="https://www.google.com/maps/embed?origin=mfe&pb=!1m3!2m1!1s3131+McKinney+Ave,+Dallas+TX+75204!6i13"
        frameborder="0"
        scrolling="no"
        marginheight="0"
        marginwidth="0"
      ></iframe>
    </div>
  )
}

export default Contact;
