require 'socket'

class Irc
  def initialize(host, port=6667, name, login_name, nickname, charcode)
    @host = host
    @port = port
    @name = name
    @login_name = login_name
    @nickname = nickname
    @socket = TCPSocket.new(@host, @port)
    @socket.set_encoding(charcode)
    @eol = "\r\n"
  end

  def connect
    send("USER #{@login_name} #{@host} #{@host} :#{@name}")
    send("NICK #{@nickname}")
    sleep 2
    thread = receive_thread
  end

  def quit
    send("QUIT")
  end

  def join(channel)
    send("JOIN #{channel}")
  end

  def privmsg(channel, msg)
    send("PRIVMSG #{channel} :#{msg}")
  end

  def pong(msg)
    send("PONG #{msg}")
  end

  private

  def send(cmd)
    @socket.write(cmd + @eol)
  end

  def exec_command(channel, cmd)
    case cmd
    when /listadd(.*)/
      privmsg(channel, "sorry, not yet")
    when /listdel(.*)/
      privmsg(channel, "comming soon...?")
    when /help(.*)/
      privmsg(channel, "usage:")
      privmsg(channel, "  twirc listadd @twitteraccount hima-jinn")
      privmsg(channel, "  twirc listdel @twitteraccount hima-jinn")
    end

  end

  def receive_thread
    begin
      Thread.new do
        while msg = @socket.gets.split
          puts "[log] recieve message : #{msg}"

          #pingpong
          pong("#{msg[1]}") if msg[0] == 'PING'

          #recieve command
          if msg[1] == 'PRIVMSG' && /^:twirc\// =~ msg[3]
             msg[3].sub!(':twirc/','')
             channel = msg[2]
             exec_command(channel, msg[3..-1].join(" "))
          end
        end
      end
    rescue
      puts "[log] unhandled exception @ pingpong thread"
    end
  end

end

