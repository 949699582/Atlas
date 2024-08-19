local Module = {}

function Module.rendezvous(param)
    print('sleep 1s before rendezvous!!!!')
    os.execute('sleep 1')
    return Sync.rendezvous(function ()
        print('rendezvous!!! sleep 3s')
        os.execute('sleep 3')
        end
    )
end

function Module.exclusion(param)
    print('sleep 1s before exclusion!!!!')
    os.execute('sleep 1')
    return Sync.exclude(function ()
        print('exclusion!!!')
        os.execute('sleep 1')
        end
    )
end

return Module
