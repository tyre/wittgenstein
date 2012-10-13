require 'rubygems'
require 'ffi-rzmq'
Thread.abort_on_exception = true

def error_check(rc)
  if ZMQ::Util.resultcode_ok?(rc)
    false
  else
    STDERR.puts "Operation failed, errno [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
    caller(1).each { |callstack| STDERR.puts(callstack) }
    true
  end
end

ctx = ZMQ::Context.create(1)

STDERR.puts "Failed to create context." unless ctx

push_thread =  Thread.new do
  push_socket = ctx.socket(ZMQ::PUSH)
  error_check(push_sock.setsockopt(ZMQ::LINGER, 0))
  rc = push_sock.bind('tcp://127.0.0.1:2200')
  error_check(rc)

  7.times do |i|
    msg = "#{i + 1} Potato"
    puts "Sending #{msg}"
    #This will block till a PULL socket connects`
    rc = push_sock.send_string(msg)
    break if error_check(rc)

    #Lets wait a second between messages
    sleep 1
  end

  # always close a socket when we're done with it otherwise
  # the context termination will hang indefinitely
  error_check(push_sock.close)
end

#Here we create two pull sockets, you'll see an alternating pattern
#of message reception between these two sockets
pull_threads = []
2.times do |i|
  pull_threads << Thread.new do
    pull_sock = ctx.socket(ZMQ::PULL)
    error_check(pull_sock.setsockopt(ZMQ::LINGER, 0))
    sleep 3
    puts "Pull #{i} connecting"
    rc = pull_sock.connect('tcp://127.0.0.1:2200')
    error_check(rc)

    #Here we receive message strings; allocate a string to receive
    # the message into
    message = ''
    rc = 0
    #On termination sockets raise an error where a call to #recv_string will
    # return an error, lets handle this nicely
    #Later, we'll learn how to use polling to handle this type of situation
    #more gracefully
    while ZMQ::Util.resultcode_ok?(rc)
      rc = pull_sock.recv_string(message)
      puts "Pull#{i}: I received a message '#{message}'"
    end

    # always close a socket when we're done with it otherwise
    # the context termination will hang indefinitely
    error_check(pull_sock.close)
    puts "Socket closed; thread terminating"
  end
end

#Wait till we're done pushing messages
push_thread.join
puts "Done pushing messages"

#Terminate the context to close all sockets
ctx.terminate
puts "Terminated context"

#Wait till the pull threads finish executing
pull_threads.each {|t| t.join}

puts "Done!"



