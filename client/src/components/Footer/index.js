import React, { Component } from "react";

// Resources
import imgTick from "../../assets/images/ic_tick.png";

import style from "./style.module.scss";

const VIEWERS = (Math.random() * 4 | 0) + 80;

class Footer extends Component {
  render() {
    return (
      <div className={style.footer}>
        <div className={style.inner}>

          {/* <div className={style.visited}>

            <div className={style.rating}>
              <div className={style.circleMark}>
                <span />
              </div>
              <div className={style.desc}>
                <div className={style.title}>
                  <span>
                    <strong>{VIEWERS} people</strong> are viewing this page
                  </span>
                </div>
                <div className={style.verified}>
                  <span className={style.verifiedImage}>
                    <img src={imgTick} alt="tick" />
                  </span>
                  <span className={style.verifiedLabel}>Verified by Proof</span>
                </div>
              </div>
            </div>

          </div> */}

          <div className={style.copyright}>
            <p>
              &copy;2019, Tranzmt, Inc. and Safewrd are trademarks of Tranzmt,
              Inc.
            </p>
          </div>
        </div>
      </div>
    );
  }
}

export default Footer;
