import sys, os
import invoke

#@invoke.task(help={'clean': "Clean externals instead of fetching them"})
#def deps(ctx, clean=False):
#    """
#    Any bootstrapping tasks, can't rely on things that don't come with `git pull`
#    """

try:
    # Local tasks in local files or fetched files.  Is discovery possible?
    from . import tasks
    ns = invoke.Collection.from_module(tasks)
    # Also need to add bootstrapping tasks from above...
    ns.add_task(deps)
    # And any config...
    run_config = {
        'encoding': "UTF8",
        'echo': True,
    }

    if os.name == 'nt':
        run_config['shell'] = "C:\\Windows\\System32\\cmd.exe"
    ns.configure({'run': run_config})
except ImportError:
    pass
