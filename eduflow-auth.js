// Shared Supabase client + role guard for the staff/admin/receptionist portal.
// Load AFTER the supabase-js CDN script:
//   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
//   <script src="eduflow-auth.js"></script>

const SUPABASE_URL = 'https://capbydzmhgllequsdhtp.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhcGJ5ZHptaGdsbGVxdXNkaHRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4ODY5NDEsImV4cCI6MjA5OTQ2Mjk0MX0.g53p79GmpEOCPf_wEYFsPW5-cFOQuJLAcGmtLNaxKw0';

// flowType 'implicit': password-reset/invite links are opened from an email
// app, almost always a different browser context than the one that
// requested them. PKCE (the library default) needs a code_verifier stored
// locally by the requesting browser, so it fails whenever the link is
// opened elsewhere. Implicit flow puts the session directly in the link
// itself, so it works regardless of where the link is opened.
const eduflowClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { flowType: 'implicit' }
});

// Role-specific signup invite codes (same idea as the existing shared platform/staff codes).
const EDUFLOW_INVITE_CODES = {
  staff: 'STAFF-INVITE-9K3PQX',
  receptionist: 'RECEPTION-INVITE-7H2WLD'
};

// Shared subject display labels — classes.subject stores short codes,
// every page renders the same French label from this one map.
const EDUFLOW_SUBJECT_LABELS = {
  fr: 'Francais',
  en: 'Anglais',
  es: 'Espagnol',
  de: 'Allemand'
};

async function eduflowGetProfile(){
  const { data: { session } } = await eduflowClient.auth.getSession();
  if (!session) return { session: null, profile: null };
  const { data: profile } = await eduflowClient
    .from('profiles')
    .select('*')
    .eq('id', session.user.id)
    .single();
  return { session, profile: profile || null };
}

function eduflowRoleHome(role){
  if (role === 'admin') return 'admin-dashboard.html';
  if (role === 'staff') return 'staff-dashboard.html';
  if (role === 'receptionist') return 'reception-dashboard.html';
  return 'login.html';
}

// Call at the top of every protected page. Redirects away and returns null
// if the visitor isn't logged in, isn't approved yet, is disabled, or has
// the wrong role for this page. Returns {session, profile} otherwise.
async function eduflowRequireRole(allowedRoles){
  const { session, profile } = await eduflowGetProfile();
  if (!session){
    window.location.replace('login.html');
    return null;
  }
  if (!profile || profile.status !== 'active'){
    await eduflowClient.auth.signOut();
    window.location.replace('login.html?reason=disabled');
    return null;
  }
  if (profile.role === 'pending'){
    await eduflowClient.auth.signOut();
    window.location.replace('login.html?reason=pending');
    return null;
  }
  if (!allowedRoles.includes(profile.role)){
    window.location.replace(eduflowRoleHome(profile.role));
    return null;
  }
  return { session, profile };
}

async function eduflowLogout(){
  await eduflowClient.auth.signOut();
  window.location.replace('login.html');
}
