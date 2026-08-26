# Organizations

This module models clinics, petshops and other professional organizations.

Key rules:
- creating an organization automatically makes the creator an ADMIN member;
- only organization admins may add or change memberships;
- membership changes are written to AuditEvent;
- veterinarians should be linked through a verified ProfessionalProfile before clinical write permissions are enabled.
