class WebcamDownloader::WgetProxy
  def initialize(_logger)
    @logger = _logger
    @cookie_path = File.join("data", "cookies.txt")

    @dns_timeout = 3     # --dns-timeout
    @connect_timeout = 4 # --connect-timeout
    @read_timeout = 4    # --read-timeout

    @dns_timeout_proxy = 10     # --dns-timeout
    @connect_timeout_proxy = 10 # --connect-timeout
    @read_timeout_proxy = 25    # --read-timeout

    @retries = 3
    @retries_proxy = 1

    @verbose = false

    @tmp_file = File.join("tmp", "tmp.tmp")

    @logger.debug "#{self.class} initialized"
  end

  property :verbose

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
    "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)",
  ]

  def download_url(url, dest, options = {} of String => String)
    referer = url
    referer = options[:referer] if options.has_key?(:referer)

    additional_options = ""
    additional_options = options[:wget_options] if options.has_key?(:wget_options)

    agent = AGENTS_LIST[rand(AGENTS_LIST.size)]

    timeouts_options = "-t #{@retries} --dns-timeout=#{@dns_timeout} --connect-timeout=#{@connect_timeout} --read-timeout=#{@read_timeout}"
    referer_options = "--referer=\"#{referer}\""
    agent_options = "--user-agent=\"#{agent}\""
    cookies_options = "--load-cookies #{@cookie_path} --keep-session-cookies --save-cookies data/cookies.txt"

    if @verbose
      verbose_options = "--verbose"
    else
      verbose_options = "--quiet"
    end

    command = "wget #{additional_options} #{timeouts_options} #{referer_options} #{agent_options} #{cookies_options} #{verbose_options} \"#{url}\" -O#{dest}"

    @logger.debug("#{self.class} wget command - #{command.to_s}")
    `#{command}`
  end
end
