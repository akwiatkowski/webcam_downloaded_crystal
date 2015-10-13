class WebcamDownloader::WgetProxy
  AGENTS_LIST = [
    "Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10; rv:33.0) Gecko/20100101 Firefox/33.0",
    "Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0",
    "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:25.0) Gecko/20100101 Firefox/29.0",
    "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko",
    "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)",
    "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)"
  ]

  def initialize
    @dns_timeout = 3 # --dns-timeout
    @connect_timeout = 4 # --connect-timeout
    @read_timeout = 4 # --read-timeout

    @dns_timeout_proxy = 10 # --dns-timeout
    @connect_timeout_proxy = 10 # --connect-timeout
    @read_timeout_proxy = 25 # --read-timeout

    @retries = 3
    @retries_proxy = 1

    @tmp_file = File.join("tmp", "wget.tmp")
    @verbose = true
  end

  property :logger, :downloader


    # Download file/image using wget
    def download_file(url, dest, options = {} of KeyType => ValueType )
      ref = options[:referer] || url
      additional_options = options[:wget_options] || ""

      # timeouts
      if current_proxy
        timeouts_command = "-t #{@retries_proxy} --dns-timeout=#{@dns_timeout_proxy} --connect-timeout=#{@connect_timeout_proxy} --read-timeout=#{@read_timeout_proxy}"
      else
        timeouts_command = "-t #{@retries} --dns-timeout=#{@dns_timeout} --connect-timeout=#{@connect_timeout} --read-timeout=#{@read_timeout}"
      end

      # quiet only without proxy
      if @verbose
        quiet_command = " --verbose"
      else
        quiet_command = " --quiet"
      end

      command = "wget #{add_options} #{timeouts_command} #{proxy_command} #{quiet_command} #{current_proxy} --referer=\"#{ref}\" --user-agent=\"#{agent}\" --load-cookies data/cookies.txt --keep-session-cookies --save-cookies data/cookies.txt \"#{url}\" -O#{dest}"

      #@logger.debug("Wget proxy command - #{command.to_s.green}")
      `#{command}`
    end

    def download_and_remove(url)
      download_file(url, @tmp_file)
      File.delete(@tmp_file) if File.exists?(@tmp_file)
    end

  end
