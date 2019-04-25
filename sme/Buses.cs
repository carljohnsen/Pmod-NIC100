using System;
using SME;

namespace PMODNIC100 
{

    [InitializedBus]
    public interface Control : IBus
    {
        bool next { get; set; }
        bool send { get; set; }
        bool build_pkg { get; set; }
        bool poll_pkgs { get; set; }
    }

    [InitializedBus]
    public interface Data : IBus
    {
        bool valid { get; set; }
        byte data { get; set; }
    }

    [InitializedBus]
    public interface DataFlow : IBus
    {
        bool ready { get; set; }
    }

    [InitializedBus]
    public interface Status : IBus
    {
        bool busy { get; set; }
        byte frame_number { get; set; }
        byte queued_pkgs { get; set; }
    }

}