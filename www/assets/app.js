function bytesToSize(bytes) {
   var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
   if (bytes == 0) return '0 Byte';
   var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
   return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
};

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
    var imageSrc = "";
    if (this.props.imageOrigin == "remote") {
      var imageSrc = this.props.data.url;
    }
    if (this.props.imageOrigin == "local") {
      var imageSrc = "pix/" + this.props.data.desc + ".jpg";
    }

    return (
      <div className="webcam">
        <h2 className="webcam-desc">{this.props.data.desc}</h2>
        <img src={imageSrc} className={ this.props.imageOrigin ? "webcam-image" : "hidden" } />
        <table className="webcam-stats-table">
          <tbody>
            <tr>
              <th>Index</th>
              <th>Interval</th>
              <th>Group</th>
              <th>Last download</th>
              <th>Download</th>
              <th>Identical</th>

              <th>Total time</th>
              <th>Avg time</th>
              <th>Total size</th>
              <th>Avg size</th>

            </tr>
            <tr>
              <td>{this.props.data.index}</td>
              <td>{this.props.data.interval}</td>
              <td>{this.props.data.group}</td>
              <td title={moment(this.props.data.last_download_at * 1000).format("YYYY-MM-DD HH:mm:ss") }>{ moment(this.props.data.last_download_at * 1000).fromNow() }s</td>
              <td>
                Attempt: {this.props.data.stats.download_attemp} <br/>
                Done: {this.props.data.stats.download_done} <br/>
                Identival: {this.props.data.stats.download_identical} <br/>
              </td>
              <td>
                Ratio: {this.props.data.stats.download_identical / this.props.data.stats.download_done}x <br/>
                Interval: {this.props.data.interval * this.props.data.stats.download_identical / this.props.data.stats.download_done}
              </td>

              <td>
                <span title={this.props.data.stats.time_download_sum}>Download: {moment(this.props.data.stats.time_download_sum * 1000).from(0, true)}</span> <br/>
                <span title={this.props.data.stats.time_process_sum}>Process: {moment(this.props.data.time_process_sum * 1000).from(0, true)}</span>
              </td>
              <td>
                Download: {Math.round(this.props.data.stats.time_download_sum * 1000.0 / this.props.data.stats.time_download_count, 2)}ms <br/>
                Process: {Math.round(this.props.data.stats.time_process_sum * 1000.0 / this.props.data.stats.time_process_count, 2)}ms <br/>
              </td>

              <td>
                Stored: {bytesToSize(this.props.data.stats.download_total_size_stored)} <br/>
                All: {bytesToSize(this.props.data.stats.download_total_size_unprocessed)}
              </td>
              <td>
                Stored: {bytesToSize(this.props.data.stats.download_total_size_stored / this.props.data.stats.download_done)} <br/>
                All: {bytesToSize(this.props.data.stats.download_total_size_unprocessed / this.props.data.stats.download_done)}
              </td>


            </tr>
          </tbody>
        </table>
      </div>
    );
  }
}

class WebcamsList extends React.Component {
  reloadLocal() {
    this.setState({ imageOrigin: "local" })
  }

  reloadRemote() {
    this.setState({ imageOrigin: "remote" })
  }

  render() {
    var webcamNodes = this.props.data.map((webcam) => {
      return (
        <Webcam data={webcam} key={webcam.desc} imageOrigin={ this.state ? this.state.imageOrigin : null }></Webcam>
      );
    });
    return (
      <div className="webcam-list">
        <div className="webcam-control">
          <a href="#" onClick={(e) => this.reloadLocal()}>Local</a>
          <a href="#" onClick={(e) => this.reloadRemote()}>Remote</a>
        </div>
        {webcamNodes}
      </div>
    );
  }
}

ReactDOM.render(<WebcamsBox url="data.json" pollInterval={180000} />, document.getElementById('content'))
