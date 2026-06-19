<!DOCTYPE html>
<html>
<head>
    <title>Employee Management</title>
</head>
<body>
    <h2>Employee List - Adithya Company</h2>
    
    @if(session('success'))
        <div style="color: green; margin-bottom: 15px;">{{ session('success') }}</div>
    @endif

    <a href="{{ route('employees.create') }}">Add New Employee</a>
    <br><br>

    <table border="1" cellpadding="10" cellspacing="0">
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Actions</th>
            </tr>
        </thead>
                <tbody>
            @if($employees->isEmpty())
                <tr>
                    <td colspan="4">No employees found.</td>
                </tr>
            @else
                @foreach($employees as $emp)
                <tr>
                    <td>{{ $emp->id }}</td>
                    <td>{{ $emp->name }}</td>
                    <td>{{ $emp->email }}</td>
                    <td>
                        <a href="{{ route('employees.edit', $emp->id) }}">Edit</a> | 
                        <form action="{{ route('employees.destroy', $emp->id) }}" method="POST" style="display:inline;">
                            @csrf
                            @method('DELETE')
                            <button type="submit" onclick="return confirm('Are you sure you want to delete this employee?')">Delete</button>
                        </form>
                    </td>
                </tr>
                @endforeach
            @endif
        </tbody>
    </table>
</body>
</html>
