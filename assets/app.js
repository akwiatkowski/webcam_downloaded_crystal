class WebcamsBox extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      data: []
    }
  }

  loadDataFromServer() {
    fetch(this.props.url)
      .then( response => response.json() )
      .then(data => this.setState({ data: data }))
      .catch(err => console.error(this.props.url, err.toString()))
  }

  componentDidMount() {
    this.loadDataFromServer();
    setInterval(this.loadDataFromServer.bind(this), this.props.pollInterval);
  }

  render() {
    return (
      <div className="webcamsBox">
        <h1>Webcams</h1>
        <WebcamsList data={this.state.data}/>
      </div>
    );
  }
}

class Webcam extends React.Component {
  render() {
    return (
      <div className="webcam">
        <h2 className="webcam-desc">{this.props.data.desc}</h2>
        <img src={this.props.data.url} />
        <table>
          <tr>
            <th>Index</th>
            <th>Interval</th>
            <th>Group</th>
            <th>Last download ago</th>
          </tr>
          <tr>
            <td>{this.props.data.index}</td>
            <td>{this.props.data.interval}</td>
            <td>{this.props.data.group}</td>
            <td>{ (Date.now() / 1000) - this.props.data.last_download_at }s</td>
          </tr>
        </table>
      </div>
    );
  }
}

class WebcamsList extends React.Component {
  render() {
    var webcamNodes = this.props.data.map((webcam) => {
      return (
        <Webcam data={webcam} key={webcam.desc}></Webcam>
      );
    });
    return (
      <div className="webcam-list">
        {webcamNodes}
      </div>
    );
  }
}

ReactDOM.render(<WebcamsBox url="data.json" pollInterval={180000} />, document.getElementById('content'))
