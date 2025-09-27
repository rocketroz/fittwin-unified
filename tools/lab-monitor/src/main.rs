use std::{
    env,
    io,
    path::Path,
    process::Command,
    time::{Duration, Instant},
};

use crossterm::{
    event::{self, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, Paragraph, Wrap},
    widgets::ListState,
    Terminal,
};

const REFRESH_INTERVAL: Duration = Duration::from_secs(2);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum StatusState {
    Ok,
    Warn,
    Fail,
}

impl StatusState {
    fn color(self) -> Color {
        match self {
            StatusState::Ok => Color::Green,
            StatusState::Warn => Color::Yellow,
            StatusState::Fail => Color::Red,
        }
    }

    fn label(self) -> &'static str {
        match self {
            StatusState::Ok => "OK",
            StatusState::Warn => "WARN",
            StatusState::Fail => "FAIL",
        }
    }
}

#[derive(Clone, Debug)]
struct StatusRow {
    label: String,
    state: StatusState,
    detail: String,
}

#[derive(Clone, Debug)]
struct Section {
    title: String,
    rows: Vec<StatusRow>,
}

struct App {
    sections: Vec<Section>,
    last_error: Option<String>,
    last_updated: Option<Instant>,
    selected_section: usize,
    selected_row: usize,
    actions: Vec<Action>,
}

impl App {
    fn new() -> Self {
        Self {
            sections: Vec::new(),
            last_error: None,
            last_updated: None,
            selected_section: 0,
            selected_row: 0,
            actions: Vec::new(),
        }
    }

    fn refresh(&mut self) {
        match collect_sections() {
            Ok(sections) => {
                self.sections = sections;
                self.actions = build_actions(&self.sections);
                self.last_error = None;
                self.last_updated = Some(Instant::now());
            }
            Err(err) => {
                self.last_error = Some(format!("{}", err));
            }
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();
    app.refresh();
    let mut last_tick = Instant::now();

    loop {
        terminal.draw(|f| draw_ui(f, &app))?;

        let timeout = REFRESH_INTERVAL
            .checked_sub(last_tick.elapsed())
            .unwrap_or_else(|| Duration::from_secs(0));

        if crossterm::event::poll(timeout)? {
            if let Event::Key(key) = event::read()? {
                if handle_key_event(&mut app, key)? {
                    break;
                }
            }
        }

        if last_tick.elapsed() >= REFRESH_INTERVAL {
            app.refresh();
            last_tick = Instant::now();
        }
    }

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;
    Ok(())
}

fn draw_ui(frame: &mut ratatui::Frame<'_>, app: &App) {
    let layout = Layout::default()
        .direction(Direction::Vertical)
        .margin(1)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(10),
            Constraint::Length(6),
        ])
        .split(frame.size());

    frame.render_widget(render_header(app), layout[0]);
    render_sections(frame, layout[1], app);
    frame.render_widget(render_footer(app), layout[2]);
}

fn render_header(app: &App) -> Paragraph {
    let mut line = vec![Span::styled("FitTwin Lab Doctor", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))];
    if let Some(ts) = app.last_updated {
        line.push(Span::raw("  "));
        line.push(Span::styled(
            format!("updated {:?} ago", ts.elapsed()),
            Style::default().fg(Color::Gray),
        ));
    }
    Paragraph::new(Line::from(line)).block(Block::default().borders(Borders::ALL))
}

fn render_sections(frame: &mut ratatui::Frame<'_>, area: Rect, app: &App) {
    let sections = &app.sections;
    let rows = sections.len().max(1);
    let constraints = vec![Constraint::Percentage((100 / rows as u16).max(1)); rows];
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints(constraints)
        .split(area);

    for (idx, section) in sections.iter().enumerate() {
        let items: Vec<ListItem> = section
            .rows
            .iter()
            .map(|row| {
                let state_span = Span::styled(row.state.label(), Style::default().fg(row.state.color()).add_modifier(Modifier::BOLD));
                let line = Line::from(vec![
                    Span::styled(format!("{:<18}", row.label), Style::default().fg(Color::White)),
                    Span::raw(" "),
                    state_span,
                    Span::raw("  "),
                    Span::styled(&row.detail, Style::default().fg(Color::Gray)),
                ]);
                ListItem::new(line)
            })
            .collect();

        let block = Block::default()
            .title(Span::styled(&section.title, Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)))
            .borders(Borders::ALL);

        if app.selected_section == idx {
            let mut list_state = ListStateWrapper::with_selected(Some(app.selected_row.min(section.rows.len().saturating_sub(1))));
            frame.render_stateful_widget(
                List::new(items)
                    .block(block)
                    .highlight_style(Style::default().bg(Color::Blue).fg(Color::White).add_modifier(Modifier::BOLD)),
                chunks[idx],
                list_state.inner_mut(),
            );
        } else {
            frame.render_widget(List::new(items).block(block), chunks[idx]);
        }
    }
}

fn render_footer(app: &App) -> Paragraph {
    let mut lines = Vec::new();
    if let Some(err) = &app.last_error {
        lines.push(Line::from(vec![Span::styled(
            format!("Last error: {}", err),
            Style::default().fg(Color::Red),
        )]));
    } else {
        lines.push(Line::from(vec![Span::styled(
            "Navigation: ↑/↓ sections, ←/→ rows, Enter = run action, Ctrl+R refresh, q quit.",
            Style::default().fg(Color::Gray),
        )]));
        if app.actions.is_empty() {
            lines.push(Line::from(vec![Span::styled(
                "No runnable actions detected.",
                Style::default().fg(Color::DarkGray),
            )]));
        } else {
            for action in &app.actions {
                lines.push(Line::from(vec![Span::styled(
                    format!("› {}", action.description),
                    Style::default().fg(Color::Cyan),
                )]));
            }
        }
    }
    Paragraph::new(lines).wrap(Wrap { trim: true }).block(Block::default().borders(Borders::ALL).title("Actions"))
}

fn collect_sections() -> Result<Vec<Section>, Box<dyn std::error::Error>> {
    let mut sections = Vec::new();

    sections.push(Section {
        title: "System".into(),
        rows: vec![
            cmd_version("node", ["-v"], "node"),
            cmd_version("npm", ["-v"], "npm"),
            java_status(),
        ],
    });

    sections.push(Section {
        title: "Android".into(),
        rows: android_rows(),
    });

    sections.push(Section {
        title: "iOS".into(),
        rows: vec![
            xcode_status(),
            cocoapods_status(),
        ],
    });

    sections.push(Section {
        title: "Ports".into(),
        rows: vec![
            port_status(3000),
            port_status(3001),
            port_status(3100),
        ],
    });

    sections.push(Section {
        title: "Projects".into(),
        rows: vec![
            path_status("shopper-lab", "frontend/nativescript/shopper-lab"),
            path_status("brand-lab", "frontend/nativescript/brand-lab"),
        ],
    });

    Ok(sections)
}

fn cmd_version(cmd: &str, args: impl IntoIterator<Item = &'static str>, label: &str) -> StatusRow {
    match Command::new(cmd).args(args).output() {
        Ok(output) if output.status.success() => {
            let text = String::from_utf8_lossy(&output.stdout).trim().to_string();
            StatusRow {
                label: label.into(),
                state: StatusState::Ok,
                detail: text,
            }
        }
        Ok(output) => StatusRow {
            label: label.into(),
            state: StatusState::Fail,
            detail: format!("exit {}", output.status),
        },
        Err(err) => StatusRow {
            label: label.into(),
            state: StatusState::Fail,
            detail: format!("{}", err),
        },
    }
}

fn java_status() -> StatusRow {
    match Command::new("/usr/libexec/java_home").arg("-v").arg("17").output() {
        Ok(output) if output.status.success() => {
            let home = String::from_utf8_lossy(&output.stdout).trim().to_string();
            StatusRow {
                label: "java".into(),
                state: StatusState::Ok,
                detail: home,
            }
        }
        _ => StatusRow {
            label: "java".into(),
            state: StatusState::Warn,
            detail: "Java 17 not detected".into(),
        },
    }
}

fn android_rows() -> Vec<StatusRow> {
    let mut rows = Vec::new();
    let android_home = env::var("ANDROID_HOME").unwrap_or_else(|_| format!("{}/Library/Android/sdk", env::var("HOME").unwrap_or_default()));
    if Path::new(&android_home).exists() {
        rows.push(StatusRow { label: "ANDROID_HOME".into(), state: StatusState::Ok, detail: android_home.clone() });
    } else {
        rows.push(StatusRow { label: "ANDROID_HOME".into(), state: StatusState::Fail, detail: format!("missing: {}", android_home) });
    }

    // sdkmanager presence
    let sdkmanager = format!("{}/cmdline-tools/latest/bin/sdkmanager", android_home);
    if Path::new(&sdkmanager).exists() {
        rows.push(StatusRow { label: "sdkmanager".into(), state: StatusState::Ok, detail: "found".into() });
    } else {
        rows.push(StatusRow { label: "sdkmanager".into(), state: StatusState::Warn, detail: "missing".into() });
    }

    rows.push(package_status(&android_home, "platform-tools", "platform-tools"));
    rows.push(package_status(&android_home, "platforms/android-34", "platforms;android-34"));
    rows.push(package_status(&android_home, "build-tools/34.0.0", "build-tools;34.0.0"));

    rows.push(adb_status());
    rows.push(device_status());

    rows
}

fn package_status(android_home: &str, relative: &str, label: &str) -> StatusRow {
    let path = format!("{}/{}", android_home, relative);
    if Path::new(&path).exists() {
        StatusRow { label: label.into(), state: StatusState::Ok, detail: "installed".into() }
    } else {
        StatusRow { label: label.into(), state: StatusState::Warn, detail: "missing".into() }
    }
}

fn adb_status() -> StatusRow {
    if let Ok(output) = Command::new("adb").arg("version").output() {
        if output.status.success() {
            let version = String::from_utf8_lossy(&output.stdout).trim().to_string();
            return StatusRow { label: "adb".into(), state: StatusState::Ok, detail: version };
        }
    }
    StatusRow { label: "adb".into(), state: StatusState::Warn, detail: "adb unavailable".into() }
}

fn device_status() -> StatusRow {
    match Command::new("adb").args(["devices", "-l"]).output() {
        Ok(output) if output.status.success() => {
            let lines: Vec<_> = String::from_utf8_lossy(&output.stdout)
                .lines()
                .skip(1)
                .filter(|line| line.trim().ends_with("device"))
                .map(|l| l.trim().to_string())
                .collect();
            if lines.is_empty() {
                StatusRow { label: "adb devices".into(), state: StatusState::Warn, detail: "none".into() }
            } else {
                StatusRow { label: "adb devices".into(), state: StatusState::Ok, detail: lines.join("; ") }
            }
        }
        _ => StatusRow { label: "adb devices".into(), state: StatusState::Warn, detail: "unable to query".into() },
    }
}

fn xcode_status() -> StatusRow {
    match Command::new("xcode-select").arg("-p").output() {
        Ok(output) if output.status.success() => {
            let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
            StatusRow { label: "xcode-select".into(), state: StatusState::Ok, detail: path }
        }
        _ => StatusRow { label: "xcode-select".into(), state: StatusState::Warn, detail: "not configured".into() },
    }
}

fn cocoapods_status() -> StatusRow {
    match Command::new("pod").arg("--version").output() {
        Ok(output) if output.status.success() => {
            let version = String::from_utf8_lossy(&output.stdout).trim().to_string();
            StatusRow { label: "cocoapods".into(), state: StatusState::Ok, detail: version }
        }
        _ => StatusRow { label: "cocoapods".into(), state: StatusState::Warn, detail: "not installed".into() },
    }
}

fn port_status(port: u16) -> StatusRow {
    let output = Command::new("lsof")
        .args(["-i", &format!("tcp:{}", port), "-sTCP:LISTEN"])
        .output();
    match output {
        Ok(out) if out.status.success() && !out.stdout.is_empty() => {
            StatusRow { label: format!("port:{}", port), state: StatusState::Ok, detail: "listening".into() }
        }
        _ => StatusRow { label: format!("port:{}", port), state: StatusState::Warn, detail: "idle".into() },
    }
}

fn path_status(label: &str, relative: &str) -> StatusRow {
    let path = Path::new(relative);
    if path.exists() {
        StatusRow { label: label.into(), state: StatusState::Ok, detail: path.display().to_string() }
    } else {
        StatusRow { label: label.into(), state: StatusState::Fail, detail: "missing".into() }
    }
}
#[derive(Clone, Debug)]
struct Action {
    label: String,
    section_idx: usize,
    row_idx: usize,
    command: Option<Vec<String>>,
    description: String,
}

#[derive(Default)]
struct ListStateWrapper(ListState);

impl ListStateWrapper {
    fn with_selected(selected: Option<usize>) -> Self {
        let mut state = ListState::default();
        state.select(selected);
        ListStateWrapper(state)
    }

    fn inner_mut(&mut self) -> &mut ListState {
        &mut self.0
    }
}
