using System;
using System.Collections.Generic;
using System.Linq;
using SME;

namespace PMODNIC100 
{

    public class NICSimulator : SimulationProcess
    {
        [InputBus] public Control ctrl;
        [InputBus] public Data send_data;
        [InputBus] public DataFlow recv;

        [OutputBus] public Data recv_data = Scope.CreateBus<Data>();
        [OutputBus] public DataFlow send = Scope.CreateBus<DataFlow>();
        [OutputBus] public Status status = Scope.CreateBus<Status>();

        byte frame_counter = 0;
        List<byte[]> pkgs;

        public NICSimulator(string filename)
        {
            // TODO vent på deres svar
        }

        public override async System.Threading.Tasks.Task Run()
        {
            while (true)
            {
                if (ctrl.poll_pkgs) 
                {
                    status.busy = true;
                    for (int i = 0; i < 24; i++) // Management cycles
                        await ClockAsync();

                    status.queued_pkgs = (byte)(pkgs.Count - frame_counter);
                    
                    status.busy = false;
                } 
                else if (ctrl.next)
                {
                    status.busy = true;
                    for (int i = 0; i < 96; i++) // Management cycles
                        await ClockAsync();

                    foreach (byte b in pkgs[frame_counter])
                    { // TODO the ready signal is currently ignored, due to the NIC chip supplying a byte each 8th cycle without the ability to stall
                        recv_data.valid = false;
                        for (int i = 0; i < 8; i++)
                            await ClockAsync();
                        recv_data.data = b;
                        recv_data.valid = true;
                    }
                    frame_counter++;
                    await ClockAsync();
                    recv_data.valid = false;

                    for (int i = 0; i < 40; i++) // Management cycles
                        await ClockAsync();

                    status.busy = false;
                }
                else if (ctrl.build_pkg)
                {
                    status.busy = true;
                    for (int i = 0; i < 88; i++) // Management cycles
                        await ClockAsync();

                    while (ctrl.build_pkg)
                    {
                        while (!send_data.valid) // Wait for a valid byte
                            await ClockAsync();

                        send.ready = true; // 'eat' a byte
                        for (int i = 0; i < 8; i++)
                        {
                            await ClockAsync();
                            send.ready = false;
                        }
                    }

                    status.busy = false;
                }
                else if (ctrl.send)
                {
                    status.busy = true;

                    for (int i = 0; i < 8; i++) // Management cycles
                        await ClockAsync();

                    status.busy = false;
                }
                await ClockAsync();
            }
        }
    }

}