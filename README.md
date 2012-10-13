## Wittgenstein

Ruby [ØMQ][1] application server.

Will serve as a quick alternative to [Redis][2] manipulation as well as lower memory overhead. Push-pull sockets are blocking and pub-sub has potential to lose messages || broadcast to no one, so use should be situation-dependent.

Initially favor push/pull system for simplicity in low-traffic scenarios.

[1]: http://zeromq.org "ZeroMQ"
[2]: http://redis.io   "Redis"