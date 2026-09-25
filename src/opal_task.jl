"""
    opal_tasks(opal; df=true)

Get all the tasks with their status at the time of the request.

# Arguments
- `opal::OpalObject`: Opal connection object
- `df::Bool=true`: Return a data frame
"""
function opal_tasks(opal::OpalObject; df::Bool=true)
    tasks = opal_get(opal, "shell", "commands")
    if !df
        return tasks
    end
    if !isnothing(tasks) && !isempty(tasks)
        id = Any[]
        type = String[]
        user = String[]
        project = String[]
        startDate = Union{Missing,String}[]
        endDate = Union{Missing,String}[]
        status = String[]
        for task in tasks
            push!(id, get(task, "id", ""))
            push!(type, get(task, "name", ""))
            push!(user, get(task, "owner", ""))
            push!(project, get(task, "project", ""))
            push!(startDate, get(task, "startTime", missing))
            et = get(task, "endTime", "")
            push!(endDate, isnothing(et) ? "" : et)
            push!(status, get(task, "status", ""))
        end
        return DataFrame(;
            id=id,
            type=type,
            user=user,
            project=project,
            startDate=startDate,
            endDate=endDate,
            status=status,
        )
    end
    return nothing
end

"""
    opal_task(opal, id)

Get the details of a specific task.

# Arguments
- `opal::OpalObject`: Opal connection object
- `id::String`: Task identifier
"""
function opal_task(opal::OpalObject, id::String)
    return opal_get(opal, "shell", "command", id)
end

"""
    opal_task_cancel(opal, id)

Tries to cancel a task.

# Arguments
- `opal::OpalObject`: Opal connection object
- `id::String`: Task identifier
"""
function opal_task_cancel(opal::OpalObject, id::String)
    try
        opal_put(
            opal,
            "shell",
            "command",
            id,
            "status";
            body="CANCELED",
            contentType="application/json",
        )
    catch
        # Ignore errors
    end
    return nothing
end

"""
    opal_task_wait(opal, id; max=nothing)

Wait for a task to complete. The task completion is defined by its status: SUCCEEDED,
FAILED or CANCELED.

# Arguments
- `opal::OpalObject`: Opal connection object
- `id::String`: Task identifier
- `max::Union{Nothing, Int}=nothing`: Maximum time (in seconds) to wait for the task completion
"""
function opal_task_wait(opal::OpalObject, id::String; max::Union{Nothing,Int}=nothing)
    status = "NA"
    waited = 0.0
    while status ∉ ("SUCCEEDED", "FAILED", "CANCELED") && (isnothing(max) || waited <= max)
        # delay is proportional to the time waited, but no more than 10s
        delay = min(10, max(1, round(waited / 10)))
        sleep(delay)
        waited += delay
        task = opal_get(opal, "shell", "command", id)
        status = task["status"]
    end
    if status ∈ ("FAILED", "CANCELED")
        throw(ErrorException("Task \"$(id)\" ended with status: $(status)"))
    end
    return nothing
end
