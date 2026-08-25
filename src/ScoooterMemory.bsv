package ScoooterMemory;

import ClientServer :: *;
import Dave :: *;
import Ehr :: *;
import FIFOF :: *;
import GetPut :: *;
import Interfaces :: *;
import Memory :: *;

typedef enum {
    FetchResponse,
    DataReadResponse,
    DataWriteResponse
} ScoooterResponseKind deriving(Bits, Eq);

module mkScoooterMemoryArbiter#(
    DaveIFC i_core,
    Server#(MemoryRequest#(32, 32), MemoryResponse#(32)) i_memory
)(Empty);
    // Reserve completion space per source so one stalled core port cannot block the others.
    FIFOF#(Tuple2#(ScoooterResponseKind, Bit#(1))) f_response_order      <- mkSizedFIFOF(4);
    FIFOF#(Tuple2#(Bit#(32), Bit#(1)))             f_fetch_response      <- mkSizedFIFOF(4);
    FIFOF#(Tuple2#(Bit#(32), Bit#(1)))             f_data_read_response  <- mkSizedFIFOF(4);
    FIFOF#(Bit#(1))                                f_data_write_response <- mkSizedFIFOF(4);

    Array#(Reg#(UInt#(3))) rg_fetch_outstanding      <- mkCReg(2, 0);
    Array#(Reg#(UInt#(3))) rg_data_read_outstanding  <- mkCReg(2, 0);
    Array#(Reg#(UInt#(3))) rg_data_write_outstanding <- mkCReg(2, 0);

    (* descending_urgency = "r_data_write_request, r_data_read_request, r_fetch_request" *)
    rule r_fetch_request if(rg_fetch_outstanding[1] < 4);
        let request <- i_core.imem_r.request.get;
        i_memory.request.put(MemoryRequest {
            write: False,
            byteen: 'hF,
            address: pack(tpl_1(request)),
            data: 0
        });
        f_response_order.enq(tuple2(FetchResponse, zeroExtend(tpl_2(request))));
        rg_fetch_outstanding[1] <= rg_fetch_outstanding[1] + 1;
    endrule

    rule r_data_read_request if(rg_data_read_outstanding[1] < 4);
        let request <- i_core.dmem_r.request.get;
        i_memory.request.put(MemoryRequest {
            write: False,
            byteen: 'hF,
            address: pack(tpl_1(request)),
            data: 0
        });
        f_response_order.enq(tuple2(DataReadResponse, tpl_2(request)));
        rg_data_read_outstanding[1] <= rg_data_read_outstanding[1] + 1;
    endrule

    rule r_data_write_request if(rg_data_write_outstanding[1] < 4);
        let request <- i_core.dmem_w.request.get;
        i_memory.request.put(MemoryRequest {
            write: True,
            byteen: tpl_3(request),
            address: pack(tpl_1(request)),
            data: tpl_2(request)
        });
        f_response_order.enq(tuple2(DataWriteResponse, tpl_4(request)));
        rg_data_write_outstanding[1] <= rg_data_write_outstanding[1] + 1;
    endrule

    rule r_route_response;
        let response <- i_memory.response.get;
        let response_info = f_response_order.first;
        case(tpl_1(response_info))
            FetchResponse:
                f_fetch_response.enq(tuple2(response.data, tpl_2(response_info)));
            DataReadResponse:
                f_data_read_response.enq(tuple2(response.data, tpl_2(response_info)));
            DataWriteResponse:
                f_data_write_response.enq(tpl_2(response_info));
        endcase
        f_response_order.deq;
    endrule

    rule r_deliver_fetch_response;
        let response = f_fetch_response.first;
        f_fetch_response.deq;
        i_core.imem_r.response.put(tuple2(tpl_1(response), truncate(tpl_2(response))));
        rg_fetch_outstanding[0] <= rg_fetch_outstanding[0] - 1;
    endrule

    rule r_deliver_data_read_response;
        let response = f_data_read_response.first;
        f_data_read_response.deq;
        i_core.dmem_r.response.put(response);
        rg_data_read_outstanding[0] <= rg_data_read_outstanding[0] - 1;
    endrule

    rule r_deliver_data_write_response;
        i_core.dmem_w.response.put(f_data_write_response.first);
        f_data_write_response.deq;
        rg_data_write_outstanding[0] <= rg_data_write_outstanding[0] - 1;
    endrule
endmodule

endpackage
