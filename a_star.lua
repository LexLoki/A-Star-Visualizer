local a_star = {}

local execute_step,start_grid,create_node,check_bound,check_surrounding,insert_closed,insert_open,prepare, insert_closed, insert_obstacle, get_node, clear_grid

local hEuc
local unit,sqrt2 = 1,math.sqrt(2)

local NodeStatus = {
	Off = 0,
	Open = 1,
	Closed = 2
}
local Colors = {
	Grid = {255,255,255},
	Default = {128,128,128},
	Closed = {255,0,0},
	Path = {0,255,0},
	Obstacle = {0,0,0},
	Target = {0,0,255},
	Yellow = {255,255,0}
}

local movements = {
	{ dir = {r=1,c=1}, cost = sqrt2 },
	{ dir = {r=1,c=0}, cost = 1 },
	{ dir = {r=1,c=-1}, cost = sqrt2 },
	{ dir = {r=0,c=1}, cost = 1 },
	{ dir = {r=0,c=-1}, cost = 1 },
	{ dir = {r=-1,c=1}, cost = sqrt2 },
	{ dir = {r=-1,c=0}, cost = 1 },
	{ dir = {r=-1,c=-1}, cost = sqrt2 },
}

function a_star.new(rows,columns,width,height)
	local self = {
		rows = rows,
		columns = columns,
		step_time = 0.08,
		is_running = false,
		size = {width = width, height = height},
		dim = {width = width/columns, height = height/rows},
		closed_list = {},
		open_list = {},
		heuristic = hEuc,
		grid = start_grid(rows,columns)
	}
	setmetatable(self, {__index=a_star})
	self:setStart(1,1)
	self:setTarget(rows,columns)

	--test stuff
	--[[
	insert_obstacle(self,8,8)
	insert_obstacle(self,8,7)
	insert_obstacle(self,8,6)
	insert_obstacle(self,7,8)
	insert_obstacle(self,6,8)

	insert_obstacle(self,3,3)
	insert_obstacle(self,3,2)
	insert_obstacle(self,2,3)

	insert_obstacle(self,8,5)
	insert_obstacle(self,8,4)
	insert_obstacle(self,8,3)
	]]
	--end test
	return self
end

function a_star:update(dt)
	if self.is_running then
		self.timer = self.timer-dt
		if self.timer < 0 then
			execute_step(self)
			self.timer = self.step_time
		end
	end
end

function a_star:startPathFinding()
	if self.is_running then
		--restart/cancelCurrentRun
	end
	self.timer = self.step_time
	self.is_running = true
	local nd = self.grid[self.start.r][self.start.c]
	nd.c = 0
	nd.f = 0
	clear_grid(self)
	insert_open(self,self.start.r,self.start.c)
	local t = {x=self.target.c,y=self.target.r}
	for i,v in pairs(self.grid) do for j,w in pairs(v) do
		w.h = self.heuristic({x=j,y=i},t)
	end end
end

function a_star:setHeuristic(hFunction)
	self.heuristic = hFunction
end

function a_star:setStart(row,column)
	if self.start then
		local t = self.grid[self.start.r][self.start.c]
		t.color = Colors.Default
	end
	self.start = {r=row,c=column}
end

function a_star:setTarget(row,column)
	if self.target then
		self.grid[self.target.r][self.target.c].color = NodeStatus.Off
	end
	self.target = {r=row,c=column}
	self.grid[self.target.r][self.target.c].color = Colors.Target
end

function a_star:draw()
	local w,h = self.dim.width, self.dim.height
	for i,v in ipairs(self.grid) do
		for j,nd in ipairs(v) do
			love.graphics.setColor(nd.color)
			love.graphics.rectangle('fill',(j-1)*w,(i-1)*h,w,h)
		end
	end
	love.graphics.setColor(Colors.Grid)
	for i,v in ipairs(self.grid) do
		for j,nd in ipairs(v) do
			love.graphics.rectangle('line',(j-1)*w,(i-1)*h,w,h)
		end
	end
end

function a_star:put_obstacle(x,y)
	local nd,r,c = get_node(self,x,y)
	if nd.status~=NodeStatus.Obstacle then
		insert_obstacle(self,r,c)
	end
end

function a_star:take_obstacle(x,y)
	local nd,r,c = get_node(self,x,y)
	if nd.color==Colors.Obstacle then
		for i,v in pairs(self.closed_list) do
			if v.node==nd then
				table.remove(self.closed_list,i)
				nd.status = NodeStatus.Off
				nd.color = Colors.Default
				break
			end
		end
	end
end

function a_star:save_maze()
	local f = io.open('data.txt')
	for i,v in ipairs(self.grid) do
		for j,nd in ipairs(v) do
			f:write(nd.color == Colors.Obstacle and 1 or 0)
		end
	end
end

-- Private

function get_node(as,x,y)
	local r,c = math.floor(y/as.dim.height+1),math.floor(x/as.dim.width+1)
	return as.grid[r][c],r,c
end

function start_grid(rows,columns)
	local grid = {}
	local row
	for i=1,rows do
		row = {}
		for j=1,columns do
			table.insert(row,create_node())
		end
		table.insert(grid,row)
	end
	return grid
end

function create_node()
	local t = {
		status = NodeStatus.Off,
		color = Colors.Default
	}
	return t
end

function execute_step(as)
	local c = as.open_list[1]
	local lowest = as.open_list[1].node.f
	local curr = c.pos
	local li = 1
	for i,v in pairs(as.open_list) do
		if v.node.f<lowest then
			lowest = v.node.f
			curr = v.pos
			li = i
		end
	end
	table.remove(as.open_list,li)
	insert_closed(as,curr.r,curr.c)
	if curr.c == as.target.c and curr.r == as.target.r then
		local t = as.grid[curr.r][curr.c]
		while t do
			t.color = Colors.Path
			t = t.parent
		end
		as.is_running = false
	else
		check_surrounding(as,curr.r,curr.c)
	end
end

function check_bound(as,r,c)
	return r>0 and r<=as.rows and c>0 and c<=as.columns
end

function check_surrounding(as,r,c)
	local t,rd,cd
	local cur,cost = as.grid[r][c]
	print('visiting node',r,c)
	for i,v in pairs(movements) do
		rd = r+v.dir.r
		cd = c+v.dir.c
		if check_bound(as,rd,cd) then
			t = as.grid[rd][cd]
			print('('..rd..','..cd..') cost: '..cur.c+v.cost)
			if t.status == NodeStatus.Off then
				insert_open(as,rd,cd)
				t.c = cur.c+v.cost
				t.f = t.h + t.c
				t.parent = cur
				print('Inserting new open ('..rd..','..cd..') with cost '..t.f)
			elseif t.status == NodeStatus.Open then
				cost = cur.c+v.cost--t.h + v.cost + cur.f
				if cost<t.c then
					print('Replacing ('..rd..','..cd..') cost from '..t.f..' to '..c)
					t.c = cost
					t.f = t.c+t.h
					t.parent = cur
				end
			end
		end
	end
end

function prepare(as)
	local tp = {x=target.c,y=target.r}
	local p = {}
	for i=1,as.rows do
		p.y = i
		for j=1,as.columns do
			p.x = j+1
			grid[i][j].h = hEuc(p,tp)
		end
	end
end

function insert_open(as,r,c)
	local node = as.grid[r][c]
	node.status = NodeStatus.Open
	table.insert(as.open_list,{
		pos = {r=r,c=c},
		node = node
	})
end

function insert_closed(as,r,c)
	local node = as.grid[r][c]
	node.status = NodeStatus.Closed
	node.color = Colors.Closed
	table.insert(as.closed_list,{
		pos = {r=r,c=c},
		node = node
	})
end

function insert_obstacle(as,r,c)
	local node = as.grid[r][c]
	node.status = NodeStatus.Closed
	node.color = Colors.Obstacle
	table.insert(as.closed_list,{
		pos = {r=r,c=c},
		node = node
	})
end

function clear_grid(self)
	local nd
	for i=#self.closed_list,1,-1 do
		nd = self.closed_list[i].node
		if nd.status == NodeStatus.Closed and nd.color ~= Colors.Obstacle then
			table.remove(self.closed_list,i)
			nd.status = NodeStatus.Off
			nd.color = Colors.Default
		end
	end
	print('-')
	self.open_list = {}
	for i,v in pairs(self.grid) do
		for j,w in pairs(v) do
			print(i,j,w.status,w.color)
			if w.status == NodeStatus.Open or w.color == Colors.Path then
				w.status = NodeStatus.Off
				w.color = Colors.Default
			end
		end
	end
end

-- Heuristic

function hEuc(position,target)
	return math.sqrt(math.pow(position.x-target.x,2)+math.pow(position.y-target.y,2))*1.5
end

function eEuc(position,target)
	return (math.abs(target.x-position.x)+math.abs(target.y-position.y))*1.5
end

return a_star