import React from "react";
import { BrowserRouter as Router, Route } from "react-router-dom";

// Pages
import Home from "./pages/Home";
import Contact from "./pages/Contact";

import Form from "./pages/Form";
import ThankYou from "./pages/ThankYou";

function App() {

  if (window.location.host.match(/^vip\./)) {
    return (
      <Router>
        <div className="App">
          <Route exact path="/" component={Form} />
          <Route exact path="/about" component={Home} />
          <Route exact path="/thankyou" component={ThankYou} />
          <Route exact path="/contact" component={Contact} />
        </div>
      </Router>
    );

  } else {
    return (
      <Router>
        <div className="App">
          <Route exact path="/" component={Home} />
          <Route exact path="/contact" component={Contact} />
          <Route exact path="/thankyou" component={ThankYou} />
          <Route exact path="/vip" component={Form} />
        </div>
      </Router>
    );
  }

}

export default App;
