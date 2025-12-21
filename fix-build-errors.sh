#!/bin/bash
# Fix build errors: TodoItem.CompletedAt and ViewModelBase.ClearError/SetError

set -e

echo "Fixing build errors..."

# -----------------------------------------------------------------------------
# Fix 1: Update TodoItem.cs to include CompletedAt property
# -----------------------------------------------------------------------------
echo "[1/3] Fixing TodoItem.cs..."

cat > src/MyDesktopApplication.Core/Entities/TodoItem.cs << 'EOF'
namespace MyDesktopApplication.Core.Entities;

public class TodoItem : EntityBase
{
    public required string Title { get; set; }
    public string? Description { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? DueDate { get; set; }
    
    public void MarkComplete()
    {
        IsCompleted = true;
        CompletedAt = DateTime.UtcNow;
    }
    
    public void MarkIncomplete()
    {
        IsCompleted = false;
        CompletedAt = null;
    }
}
EOF

echo "  ✓ Fixed TodoItem.cs (added CompletedAt property)"

# -----------------------------------------------------------------------------
# Fix 2: Update ViewModelBase.cs to include ClearError/SetError methods
# -----------------------------------------------------------------------------
echo "[2/3] Fixing ViewModelBase.cs in Shared project..."

cat > src/MyDesktopApplication.Shared/ViewModels/ViewModelBase.cs << 'EOF'
using CommunityToolkit.Mvvm.ComponentModel;

namespace MyDesktopApplication.Shared.ViewModels;

public abstract partial class ViewModelBase : ObservableObject
{
    [ObservableProperty]
    private bool _isBusy;
    
    [ObservableProperty]
    private string? _errorMessage;
    
    /// <summary>
    /// Clears any error message.
    /// </summary>
    protected void ClearError()
    {
        ErrorMessage = null;
    }
    
    /// <summary>
    /// Sets an error message.
    /// </summary>
    protected void SetError(string message)
    {
        ErrorMessage = message;
    }
    
    /// <summary>
    /// Sets error from an exception.
    /// </summary>
    protected void SetError(Exception ex)
    {
        ErrorMessage = ex.Message;
    }
    
    /// <summary>
    /// Returns true if there's an error message.
    /// </summary>
    public bool HasError => !string.IsNullOrEmpty(ErrorMessage);
}
EOF

echo "  ✓ Fixed ViewModelBase.cs (added ClearError/SetError methods)"

# -----------------------------------------------------------------------------
# Fix 3: Rebuild and test
# -----------------------------------------------------------------------------
echo "[3/3] Rebuilding..."

dotnet build --verbosity quiet

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "Running tests..."
    dotnet test --verbosity quiet
else
    echo ""
    echo "❌ Build failed - check errors above"
    exit 1
fi
