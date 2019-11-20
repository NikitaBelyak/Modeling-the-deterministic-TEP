module Net
using PyPlot

function print_net(lines)
    n_nodes = size(unique([lines[:,2]; lines[:,3]]),1)
    r = 2;
    nodes = [r*cos.(collect(0:2*pi/n_nodes:2*pi - 2*pi/n_nodes )), r*sin.(collect(0:2*pi/n_nodes:2*pi - 2*pi/n_nodes ))]

    figure()
    scatter(nodes[1,:],nodes[2,:],".")
    annotate("22",
    	xy=[nodes[1,1];nodes[2,1]],
        xycoords="axes fraction",
	xytext=[nodes[1,:],nodes[2,:]],
	textcoords="offset points",
	fontsize=11.0,
	ha="right",
	va="bottom")

end

end
