vsim fifo_tb
add wave clk
add wave rst
add wave wr
add wave rd
add wave full
add wave empty
add wave wr_data
add wave rd_data

# force -freeze clk 0 0, 1 {50 ns} -r 100
# force rst 1
run 1000
#force rst 0
# run 300
# force rst 1
#run 400
# force rst 0
# run 200

