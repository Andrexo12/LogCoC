from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database.db import get_db
from models.audit import AuditLog
from routes.auth import require_role
from models.user import User

router = APIRouter(prefix="/audit", tags=["Audit Log"])

@router.get("/")
def get_audit_logs(db: Session = Depends(get_db), current_user: User = Depends(require_role("admin"))):
    logs = db.query(
        AuditLog, User.email, User.first_name, User.last_name
    ).outerjoin(User, AuditLog.user_id == User.id).order_by(AuditLog.created_at.desc()).all()
    
    result = []
    for log, email, first, last in logs:
        name = f"{first or ''} {last or ''}".strip()
        user_display = f"{name} ({email})" if name else (email or "Sistema")
        result.append({
            "id": log.id,
            "action": log.action,
            "target": log.target,
            "changes": log.changes,
            "created_at": log.created_at,
            "user": user_display
        })
    return result

def log_action(db: Session, user_id: int, action: str, target: str, changes: str = None):
    try:
        new_log = AuditLog(
            user_id=user_id,
            action=action,
            target=target,
            changes=changes
        )
        db.add(new_log)
        db.commit()
    except Exception as e:
        print(f"Failed to log action: {e}")
