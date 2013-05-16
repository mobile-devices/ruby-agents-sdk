
Basically you have a Redis object created for each agent. You have nothing to create or configure, just use it.

For instance :

    def new_presence_from_device(meta, payload, account)
      # on each presence received, we set the redis key 'pom' to 'pyro' value
      redis['pom'] ='pyro'
    end


@see documentation [on official redis webwite](http://redis.io/).
