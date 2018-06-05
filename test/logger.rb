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

Object.include Logger::Severity

class StringIO
  def initialize
    @lines = []
  end

  def readlines
    @lines
  end

  def inspect
    @lines.join "\n"
  end

  alias to_s inspect

  def close; end

  def write(msg)
    @lines << msg
  end
end

assert 'Logger#level', 'attribute accessors' do
  logger = Logger.new(nil)

  logger.level = UNKNOWN
  assert_equal(UNKNOWN, logger.level)

  logger.level = INFO
  assert_equal(INFO, logger.level)

  logger.level = ERROR
  assert_equal(ERROR, logger.level)

  logger.level = WARN
  assert_equal(WARN, logger.level)

  assert_raise(TypeError) { logger.level = 'warn' }
end

assert 'Logger#level', 'severity?' do
  logger = Logger.new(nil)

  logger.level = DEBUG
  assert_true(logger.debug?)
  assert_true(logger.info?)

  logger.level = INFO
  assert_true(!logger.debug?)
  assert_true(logger.info?)
  assert_true(logger.warn?)

  logger.level = WARN
  assert_true(!logger.info?)
  assert_true(logger.warn?)
  assert_true(logger.error?)

  logger.level = ERROR
  assert_true(!logger.warn?)
  assert_true(logger.error?)
  assert_true(logger.fatal?)

  logger.level = FATAL
  assert_true(!logger.error?)
  assert_true(logger.fatal?)

  logger.level = UNKNOWN
  assert_true(!logger.error?)
  assert_true(!logger.fatal?)
end

assert 'Logger#progname' do
  logger = Logger.new(nil)

  assert_nil(logger.progname)

  logger.progname = 'name'
  assert_equal('name', logger.progname)
end

assert 'Logger#write' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger << 'message'
  assert_equal 'message', logdev.to_s
end

assert 'Logger#add', 'severity+message' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  begin
    def Time.now
      Time.mktime(2018, 1, 2, 3, 4, 5, 67_890)
    end
    logger.add INFO, 'message'
  ensure
    def Time.now
      new
    end
  end

  assert_include logdev.to_s, 'I, [2018-01-02T03:04:05.067890'
  assert_include logdev.to_s, ']  INFO -- : message'
end

assert 'Logger#add', 'severity+proc' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger.add(DEBUG) { 'message' }

  assert_equal 'D, [', logdev.to_s[0..3]
  assert_include logdev.to_s, '] DEBUG -- : message'
end

assert 'Logger#add', 'severity+message+progname' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger.add INFO, 'message', 'mruby'

  assert_equal 'I, [', logdev.to_s[0..3]
  assert_include logdev.to_s, ']  INFO -- mruby: message'
end

assert 'Logger#info' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger.info 'message'

  assert_equal 'I, [', logdev.to_s[0..3]
  assert_include logdev.to_s, ']  INFO -- : message'
end

assert 'Logger#debug' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger.debug 'message'

  assert_equal 'D, [', logdev.to_s[0..3]
  assert_include logdev.to_s, '] DEBUG -- : message'
end

assert 'Logger#info' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger.info 'message'

  assert_equal 'I, [', logdev.to_s[0..3]
  assert_include logdev.to_s, ']  INFO -- : message'
end

assert 'Logger#warn' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger.warn 'message'

  assert_equal 'W, [', logdev.to_s[0..3]
  assert_include logdev.to_s, ']  WARN -- : message'
end

assert 'Logger#error' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger.error 'message'

  assert_equal 'E, [', logdev.to_s[0..3]
  assert_include logdev.to_s, '] ERROR -- : message'
end

assert 'Logger#fatal' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger.fatal 'message'

  assert_equal 'F, [', logdev.to_s[0..3]
  assert_include logdev.to_s, '] FATAL -- : message'
end

assert 'Logger#unknown' do
  logdev = StringIO.new
  logger = Logger.new(logdev)

  logger.unknown 'message'

  assert_equal 'A, [', logdev.to_s[0..3]
  assert_include logdev.to_s, ']   ANY -- : message'
end

assert 'Logger.log', 'path' do
  begin
    file = File.join(File.dirname(__FILE__), 'log.txt')

    File.delete(file) if File.exist? file

    logger = Logger.new(file)

    logger.close
    assert_true  File.exist?(file)
    assert_false File.zero?(file)

    logger.reopen
    logger << 'message'
    assert_equal IO.read(file).split("\n")[1], 'message'

    logger.close
    assert_raise(IOError, RuntimeError) { logger << 'message' }

    logger.reopen
    assert_nothing_raised { logger << 'message' }
    assert_equal IO.read(file).split("\n")[1], 'messagemessage'
  ensure
    logger.close      if logger
    File.delete(file) if File.exist? file
  end
end
