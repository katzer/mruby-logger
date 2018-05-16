# MIT License
#
# Copyright (c) 2017 Sebastian Katzer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# The Logger class provides a simple but sophisticated logging utility that
# you can use to output messages.
class Logger
  # Logging severity.
  module Severity
    # Low-level information, mostly for developers.
    DEBUG = 0
    # Generic (useful) information about system operation.
    INFO = 1
    # A warning.
    WARN = 2
    # A handleable error condition.
    ERROR = 3
    # An unhandleable error that results in a program crash.
    FATAL = 4
    # An unknown message that should always be logged.
    UNKNOWN = 5
  end

  include Severity

  ProgName = "#{File.basename(__FILE__)}/1.2.7".freeze

  # Logging severity threshold (e.g. <tt>Logger::INFO</tt>).
  attr_reader :level

  # Set logging severity threshold.
  #
  # +severity+:: The Severity of the log message.
  def level=(severity)
    raise TypeError, "invalid log level: #{severity}" if !severity.is_a? Integer
    @level = severity
  end

  # Set date-time format.
  #
  # +datetime_format+:: A string suitable for passing to +strftime+.
  def datetime_format=(datetime_format)
    @default_formatter.datetime_format = datetime_format
  end

  # Returns the date format being used.  See #datetime_format=
  def datetime_format
    @default_formatter.datetime_format
  end

  # Logging formatter, as a +Proc+ that will take four arguments and
  # return the formatted message. The arguments are:
  #
  # +severity+:: The Severity of the log message.
  # +time+:: A Time instance representing when the message was logged.
  # +progname+:: The #progname configured, or passed to the logger method.
  # +msg+:: The _Object_ the user passed to the log message; not necessarily a
  #         String.
  #
  # The block should return an Object that can be written to the logging
  # device via +write+.  The default formatter is used when no formatter is
  # set.
  attr_accessor :formatter

  # Program name to include in log messages.
  attr_accessor :progname

  # Returns +true+ if the current severity level allows for the printing of
  # +DEBUG+ messages.
  def debug?; @level <= DEBUG; end

  # Returns +true+ if the current severity level allows for the printing of
  # +INFO+ messages.
  def info?; @level <= INFO; end

  # Returns +true+ if the current severity level allows for the printing of
  # +WARN+ messages.
  def warn?; @level <= WARN; end

  # Returns +true+ if the current severity level allows for the printing of
  # +ERROR+ messages.
  def error?; @level <= ERROR; end

  # Returns +true+ if the current severity level allows for the printing of
  # +FATAL+ messages.
  def fatal?; @level <= FATAL; end

  #
  # :call-seq:
  #   Logger.new(logdev)
  #   Logger.new(logdev, level: :info)
  #   Logger.new(logdev, progname: 'progname')
  #   Logger.new(logdev, formatter: formatter)
  #   Logger.new(logdev, datetime_format: '%Y-%m-%d %H:%M:%S')
  #
  # === Args
  #
  # +logdev+::
  #   The log device.  This is a filename (String) or IO object (typically
  #   +STDOUT+, +STDERR+, or an open file).
  # +level+::
  #   Logging severity threshold. Default values is Logger::DEBUG.
  # +progname+::
  #   Program name to include in log messages. Default value is nil.
  # +formatter+::
  #   Logging formatter. Default values is an instance of Logger::Formatter.
  # +datetime_format+::
  #   Date and time format. Default value is '%Y-%m-%d %H:%M:%S'.
  #
  # === Description
  #
  # Create an instance.
  #
  def initialize(logdev, opts = {})
    self.level           = opts[:level] || DEBUG
    self.progname        = opts[:progname]
    @default_formatter   = Formatter.new
    self.datetime_format = opts[:datetime_format]
    self.formatter       = formatter
    @logdev              = logdev ? LogDevice.new(logdev) : nil
  end

  #
  # :call-seq:
  #   Logger#reopen
  #   Logger#reopen(logdev)
  #
  # === Args
  #
  # +logdev+::
  #   The log device.  This is a filename (String) or IO object (typically
  #   +STDOUT+, +STDERR+, or an open file).  reopen the same filename if
  #   it is +nil+, do nothing for IO.  Default is +nil+.
  #
  # === Description
  #
  # Reopen a log device.
  #
  def reopen(logdev = nil)
    @logdev.reopen(logdev) if @logdev
    self
  end

  #
  # :call-seq:
  #   Logger#add(severity, message = nil, progname = nil) { ... }
  #
  # === Args
  #
  # +severity+::
  #   Severity.  Constants are defined in Logger namespace: +DEBUG+, +INFO+,
  #   +WARN+, +ERROR+, +FATAL+, or +UNKNOWN+.
  # +message+::
  #   The log message.  A String or Exception.
  # +progname+::
  #   Program name string.  Can be omitted.
  # +block+::
  #   Can be omitted.  Called to get a message string if +message+ is nil.
  #
  # === Return
  #
  # When the given severity is not high enough (for this particular logger),
  # log no message, and return +true+.
  #
  # === Description
  #
  # Log a message if the given severity is high enough.  This is the generic
  # logging method.  Users will be more inclined to use #debug, #info, #warn,
  # #error, and #fatal.
  #
  # <b>Message format</b>: +message+ can be any object, but it has to be
  # converted to a String in order to log it.  Generally, +inspect+ is used
  # if the given object is not a String.
  # A special case is an +Exception+ object, which will be printed in detail,
  # including message, class, and backtrace.  See #msg2str for the
  # implementation if required.
  #
  def add(severity, message = nil, progname = nil)
    severity ||= UNKNOWN

    return true if !@logdev || severity < @level

    progname ||= @progname

    message = yield if message.nil? && block_given?

    @logdev.write(
      format_message(format_severity(severity), Time.now, progname, message)
    )

    true
  end

  alias log add

  #
  # Dump given message to the log device without any formatting. If no log
  # device exists, return +nil+.
  #
  def <<(msg)
    @logdev.write(msg) if @logdev
  end

  alias write <<

  #
  # Log a +DEBUG+ message.
  #
  # See #info for more information.
  #
  def debug(message = nil, progname = nil, &block)
    add(DEBUG, message, progname, &block)
  end

  #
  # :call-seq:
  #   info(message)
  #   info(progname, &block)
  #
  # Log an +INFO+ message.
  #
  # +message+:: The message to log; does not need to be a String.
  # +progname+:: In the block form, this is the #progname to use in the
  #              log message.  The default can be set with #progname=.
  # +block+:: Evaluates to the message to log.  This is not evaluated unless
  #           the logger's level is sufficient to log the message.  This
  #           allows you to create potentially expensive logging messages that
  #           are only called when the logger is configured to show them.
  #
  # === Examples
  #
  #   logger.info("MainApp") { "Received connection from #{ip}" }
  #   # ...
  #   logger.info "Waiting for input from user"
  #   # ...
  #   logger.info { "User typed #{input}" }
  #
  # You'll probably stick to the second form above, unless you want to provide a
  # program name (which you can do with #progname= as well).
  #
  # === Return
  #
  # See #add.
  #
  def info(message = nil, progname = nil, &block)
    add(INFO, message, progname, &block)
  end

  #
  # Log a +WARN+ message.
  #
  # See #info for more information.
  #
  def warn(message = nil, progname = nil, &block)
    add(WARN, message, progname, &block)
  end

  #
  # Log an +ERROR+ message.
  #
  # See #info for more information.
  #
  def error(message = nil, progname = nil, &block)
    add(ERROR, message, progname, &block)
  end

  #
  # Log a +FATAL+ message.
  #
  # See #info for more information.
  #
  def fatal(message = nil, progname = nil, &block)
    add(FATAL, message, progname, &block)
  end

  #
  # Log an +UNKNOWN+ message.  This will be printed no matter what the logger's
  # level is.
  #
  # See #info for more information.
  #
  def unknown(message = nil, progname = nil, &block)
    add(UNKNOWN, message, progname, &block)
  end

  #
  # Close the logging device.
  #
  def close
    @logdev.close if @logdev
  end

  private

  # Severity label for logging (max 5 chars).
  SEV_LABEL = %w[DEBUG INFO WARN ERROR FATAL ANY]

  def format_severity(severity)
    SEV_LABEL[severity] || 'ANY'
  end

  def format_message(severity, datetime, progname, msg)
    (@formatter || @default_formatter).call(severity, datetime, progname, msg)
  end

  # Default formatter for log messages.
  class Formatter
    Format = "%s, [%s #%d] %5s -- %s: %s\n".freeze

    attr_accessor :datetime_format

    def initialize
      @datetime_format = nil
    end

    def call(sev, time, prog, msg)
      format \
        Format, sev[0], format_datetime(time), $$ || 0, sev, prog, msg2str(msg)
    end

    private

    def format_datetime(t)
      format (@datetime_format || '%04d-%02d-%02dT%02d:%02d:%02d.%06d'), \
             t.year, t.mon, t.day, t.hour, t.min, t.sec, t.usec
    rescue
      t.asctime
    end

    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "#{msg.message} (#{msg.class})\n" << (msg.backtrace || []).join("\n")
      else
        msg.inspect
      end
    end
  end

  # Device used for logging messages.
  class LogDevice
    def initialize(log = nil)
      @dev = @filename = nil

      dev_set(log)
    end

    attr_reader :dev, :filename

    def write(message)
      @dev.write(message)
    end

    def close
      @dev.close
    rescue
      nil
    end

    def reopen(log = nil)
      # reopen the same filename if no argument, do nothing for IO
      log ||= @filename if @filename

      return self unless log

      if @filename && @dev
        close
        @filename = nil
      end

      dev_set(log)

      self
    end

    private

    def dev_set(log)
      if log.respond_to?(:write) && log.respond_to?(:close)
        @dev = log
      else
        @dev      = open_logfile(log)
        @dev.sync = true
        @filename = log
      end
    end

    def open_logfile(filename)
      open(filename, 'a+')
    rescue
      create_logfile(filename)
    end

    def create_logfile(filename)
      logdev = open(filename, 'a+')
      logdev.flock(File::LOCK_EX)
      logdev.sync = true
      add_log_header(logdev)
      logdev.flock(File::LOCK_UN)
      logdev
    end

    def add_log_header(file)
      return unless File.zero? file
      file.write(
        "# Logfile created on %s by %s\n" % Time.now.to_s, Logger::ProgName
      )
    end
  end
end
