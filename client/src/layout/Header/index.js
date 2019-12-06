import React, { Component } from "react";
import { withRouter } from 'react-router-dom'

// Components
import ButtonLink from "../../components/ButtonLink";

// Style
import imgLogo from "../../assets/images/safewrd_logo.svg";
import style from "./style.module.scss";

class Header extends Component {
  render() {

    const { history } = this.props;
    const { pathname } = history.location;

    if (window.location.host.match(/^vip\./)) {
      return (
        <div className={style.header}>
          <div className={style.logo}>
            <img src={imgLogo} alt="logo" />
            <span>SafeWrd</span>
          </div>
          <div className={style.links}>
            <ButtonLink
              label="VIP"
              active={pathname === '/'}
              onClick={() => history.push('/')}
            />
            <ButtonLink
              label="About"
              active={pathname === '/about'}
              onClick={() => history.push('/about')}
            />
            <ButtonLink
              label="Contact us"
              active={pathname === '/contact'}
              onClick={() => history.push('/contact')}
            />
          </div>
        </div>
      );
    } else {
      return (
        <div className={style.header}>
          <div className={style.logo}>
            <img src={imgLogo} alt="logo" />
            <span>SafeWrd</span>
          </div>
          <div className={style.links}>
            <ButtonLink
              label="VIP"
              active={pathname === '/vip'}
              onClick={() => history.push('/vip')}
            />
            <ButtonLink
              label="About"
              active={pathname === '/'}
              onClick={() => history.push('/')}
            />
            <ButtonLink
              label="Contact us"
              active={pathname === '/contact'}
              onClick={() => history.push('/contact')}
            />
          </div>

        </div>
      );
    }
  }
}

export default withRouter(Header);
