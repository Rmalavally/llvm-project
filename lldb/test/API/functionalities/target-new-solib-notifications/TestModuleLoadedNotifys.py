"""
Test how many times newly loaded binaries are notified;
they should be delivered in batches instead of one-by-one.
"""

from __future__ import print_function


import lldb
from lldbsuite.test.decorators import *
from lldbsuite.test.lldbtest import *
from lldbsuite.test import lldbutil

class ModuleLoadedNotifysTestCase(TestBase):

    mydir = TestBase.compute_mydir(__file__)
    NO_DEBUG_INFO_TESTCASE = True

    # DynamicLoaderDarwin should batch up notifications about
    # newly added/removed libraries.  Other DynamicLoaders may
    # not be written this way.
    @skipUnlessDarwin

    def setUp(self):
        # Call super's setUp().
        TestBase.setUp(self)
        # Find the line number to break inside main().
        self.line = line_number('main.cpp', '// breakpoint')

    def test_launch_notifications(self):
        """Test that lldb broadcasts newly loaded libraries in batches."""
        self.build()
        exe = self.getBuildArtifact("a.out")
        self.dbg.SetAsync(False)

        listener = self.dbg.GetListener()
        listener.StartListeningForEventClass(
            self.dbg,
            lldb.SBTarget.GetBroadcasterClassName(),
            lldb.SBTarget.eBroadcastBitModulesLoaded | lldb.SBTarget.eBroadcastBitModulesUnloaded)

        # Create a target by the debugger.
        target = self.dbg.CreateTarget(exe)
        self.assertTrue(target, VALID_TARGET)

        # break on main
        breakpoint = target.BreakpointCreateByName('main', 'a.out')

        event = lldb.SBEvent()
        # CreateTarget() generated modules-loaded events; consume them & toss
        while listener.GetNextEvent(event):
            True

        error = lldb.SBError()
        process = target.Launch(listener,
                                None,      # argv
                                None,      # envp
                                None,      # stdin_path
                                None,      # stdout_path
                                None,      # stderr_path
                                None,      # working directory
                                0,         # launch flags
                                False,     # Stop at entry
                                error)     # error

        self.assertTrue(
            process.GetState() == lldb.eStateStopped,
            PROCESS_STOPPED)

        total_solibs_added = 0
        total_solibs_removed = 0
        total_modules_added_events = 0
        total_modules_removed_events = 0
        while listener.GetNextEvent(event):
            if lldb.SBTarget.EventIsTargetEvent(event):
                if event.GetType() == lldb.SBTarget.eBroadcastBitModulesLoaded:
                    solib_count = lldb.SBTarget.GetNumModulesFromEvent(event)
                    total_modules_added_events += 1
                    total_solibs_added += solib_count
                    if self.TraceOn():
                        # print all of the binaries that have been added
                        added_files = []
                        i = 0
                        while i < solib_count:
                            module = lldb.SBTarget.GetModuleAtIndexFromEvent(i, event)
                            added_files.append(module.GetFileSpec().GetFilename())
                            i = i + 1
                        print("Loaded files: %s" % (', '.join(added_files)))

                if event.GetType() == lldb.SBTarget.eBroadcastBitModulesUnloaded:
                    solib_count = lldb.SBTarget.GetNumModulesFromEvent(event)
                    total_modules_removed_events += 1
                    total_solibs_removed += solib_count
                    if self.TraceOn():
                        # print all of the binaries that have been removed
                        removed_files = []
                        i = 0
                        while i < solib_count:
                            module = lldb.SBTarget.GetModuleAtIndexFromEvent(i, event)
                            removed_files.append(module.GetFileSpec().GetFilename())
                            i = i + 1
                        print("Unloaded files: %s" % (', '.join(removed_files)))
        

        # This is testing that we get back a small number of events with the loaded 
        # binaries in batches.  Check that we got back more than 1 solib per event.  
        # In practice on Darwin today, we get back two events for a do-nothing c 
        # program: a.out and dyld, and then all the rest of the system libraries.

        avg_solibs_added_per_event = int(float(total_solibs_added) / float(total_modules_added_events))
        self.assertGreater(avg_solibs_added_per_event, 1)
