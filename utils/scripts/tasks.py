import subprocess
import json
import os
import sys
import time

def read_io(pid):
    try:
        with open(f'/proc/{pid}/io', 'r') as f:
            read_bytes = 0
            write_bytes = 0
            for line in f:
                if line.startswith('read_bytes:'):
                    read_bytes = int(line.split()[1])
                elif line.startswith('write_bytes:'):
                    write_bytes = int(line.split()[1])
            return read_bytes, write_bytes
    except Exception:
        return 0, 0

def main():
    sort_field = sys.argv[1] if len(sys.argv) > 1 else "-%cpu"
    
    cpu_cores = os.cpu_count() or 1
    
    try:
        hypr_out = subprocess.check_output(['hyprctl', 'clients', '-j']).decode('utf-8')
        clients = json.loads(hypr_out)
        app_pids = {c['pid']: c['class'] or c['title'] for c in clients if c['pid'] > 0}
    except Exception:
        app_pids = {}

    gpu_mem = {}
    try:
        nvidia_out = subprocess.check_output(['nvidia-smi', '--query-compute-apps=pid,used_memory', '--format=csv,noheader,nounits']).decode('utf-8')
        for line in nvidia_out.strip().split('\n'):
            if not line: continue
            parts = line.split(',')
            if len(parts) == 2:
                gpu_mem[int(parts[0])] = int(parts[1].strip()) * 1024 * 1024 # Convert MiB to bytes
    except Exception:
        pass
        
    try:
        ps_out = subprocess.check_output(['ps', 'axo', 'pid,ppid,comm,%cpu,%mem,rss,share']).decode('utf-8')
    except Exception:
        print(json.dumps({"apps": [], "processes": []}))
        return
        
    lines = ps_out.strip().split('\n')
    all_procs = {}
    
    current_time = time.time()
    
    for line in lines[1:]:
        parts = line.split(None, 6)
        if len(parts) < 7: continue
        try:
            pid = int(parts[0])
            ppid = int(parts[1])
            name = parts[2]
            # Normalize CPU usage to 100% max system-wide
            cpu = float(parts[3]) / cpu_cores
            mem_pct = float(parts[4])
            rss_kb = int(parts[5]) if parts[5] != '-' else 0
            share_kb = int(parts[6]) if parts[6] != '-' else 0

            # IO calculation
            rbytes, wbytes = read_io(pid)
            
            all_procs[pid] = {
                "pid": pid,
                "ppid": ppid,
                "name": name,
                "cpu": cpu,
                "mem_pct": mem_pct,
                "rss": rss_kb * 1024,
                "share": share_kb * 1024,
                "gpu": gpu_mem.get(pid, 0),
                "rbytes": rbytes,
                "wbytes": wbytes,
                "io_rate": 0,
                "children": []
            }
        except Exception: pass

    # IO Cache logic for computing rate (B/s)
    cache_file = "/tmp/caelestia_io_cache.json"
    old_cache = {}
    try:
        with open(cache_file, "r") as f:
            old_cache = json.load(f)
    except Exception: pass

    new_cache = {}
    for pid, proc in all_procs.items():
        spid = str(pid)
        total_io = proc['rbytes'] + proc['wbytes']
        if spid in old_cache:
            time_diff = current_time - old_cache[spid]['time']
            io_diff = total_io - old_cache[spid]['io']
            if time_diff > 0 and io_diff > 0:
                proc['io_rate'] = io_diff / time_diff
        
        new_cache[spid] = {"io": total_io, "time": current_time}
    
    try:
        with open(cache_file, "w") as f:
            json.dump(new_cache, f)
    except Exception: pass
        
    for pid, proc in all_procs.items():
        if proc['ppid'] in all_procs:
            all_procs[proc['ppid']]['children'].append(pid)
            
    def get_descendants(pid):
        desc = []
        if pid in all_procs:
            for child in all_procs[pid]['children']:
                desc.append(child)
                desc.extend(get_descendants(child))
        return desc

    grouped_pids = set()
    apps = []
    
    for pid, app_name in app_pids.items():
        if pid not in all_procs: continue
        
        proc_ids = [pid] + get_descendants(pid)
        grouped_pids.update(proc_ids)
        
        total_cpu = sum(all_procs[p]['cpu'] for p in proc_ids if p in all_procs)
        total_rss = sum(all_procs[p]['rss'] for p in proc_ids if p in all_procs)
        total_share = sum(all_procs[p]['share'] for p in proc_ids if p in all_procs)
        total_gpu = sum(all_procs[p]['gpu'] for p in proc_ids if p in all_procs)
        total_io_rate = sum(all_procs[p]['io_rate'] for p in proc_ids if p in all_procs)
        
        apps.append({
            "pid": pid,
            "name": app_name,
            "cpu": round(total_cpu, 1),
            "rss": total_rss,
            "io": total_io_rate,
            "gpu": total_gpu,
            "count": len(proc_ids)
        })
        
    processes = []
    for pid, proc in all_procs.items():
        if pid not in grouped_pids and proc['rss'] > 0: 
            processes.append({
                "pid": pid,
                "name": proc['name'],
                "cpu": round(proc['cpu'], 1),
                "rss": proc['rss'],
                "io": proc['io_rate'],
                "gpu": proc['gpu'],
                "count": 1
            })
            
    def apply_sort(items, field):
        rev = field.startswith("-")
        key = field.lstrip("-")
        
        if key == "%cpu":
            items.sort(key=lambda x: x['cpu'], reverse=rev)
        elif key == "%mem":
            items.sort(key=lambda x: x['rss'], reverse=rev)
        elif key == "%io":
            items.sort(key=lambda x: x['io'], reverse=rev)
        elif key == "%gpu":
            items.sort(key=lambda x: x['gpu'], reverse=rev)
        else:
            items.sort(key=lambda x: x['cpu'], reverse=True)
            
    apply_sort(apps, sort_field)
    apply_sort(processes, sort_field)
    
    print(json.dumps({
        "apps": apps,
        "processes": processes
    }))

if __name__ == "__main__":
    main()