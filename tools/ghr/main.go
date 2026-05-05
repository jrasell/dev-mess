package main

import (
	"context"
	"fmt"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/google/go-github/v85/github"
	"github.com/pterm/pterm"
	"github.com/urfave/cli/v3"
	"golang.org/x/oauth2"
)

func main() {
	if err := runCLIApp(os.Args); err != nil {
		pterm.Error.Println(err)
		os.Exit(1)
	}
	os.Exit(0)
}

type prResult struct {
	repo     string
	pr       *github.PullRequest
	optional bool
	notes    string
}

func runCLIApp(args []string) error {
	app := &cli.Command{
		Name: "ghr",
		Usage: strings.TrimSpace(`
GitHub Review (ghr) lists open pull requests that are pending the authenticated
user's review across one or more GitHub repositories. Each PR is classified as
either "required" (needs attention) or "optional" (already substantively
reviewed by someone else with no new commits since).`),
		Flags: []cli.Flag{
			&cli.StringSliceFlag{
				Name:    "repo",
				Aliases: []string{"r"},
				Usage:   "Repository in owner/name format (repeatable)",
			},
			&cli.StringFlag{
				Name:    "token",
				Aliases: []string{"t"},
				Usage:   "GitHub Personal Access Token (falls back to GITHUB_TOKEN env var)",
			},
		},
		UseShortOptionHandling: true,
		Action: func(cliCtx context.Context, cmd *cli.Command) error {
			token := cmd.String("token")
			if token == "" {
				token = os.Getenv("GITHUB_TOKEN")
			}
			if token == "" {
				return fmt.Errorf("Please specify the GitHub token to use.")
			}

			repos := cmd.StringSlice("repo")
			if len(repos) == 0 {
				return fmt.Errorf("Please specify at least one repository to check.")
			}

			ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: token})
			tc := oauth2.NewClient(cliCtx, ts)
			client := github.NewClient(tc)

			// Resolve the authenticated user so we know whose review queue to check.
			me, _, err := client.Users.Get(cliCtx, "")
			if err != nil {
				return fmt.Errorf("resolving authenticated user: %w", err)
			}
			myLogin := me.GetLogin()

			var results []prResult

			for _, repo := range repos {
				parts := strings.SplitN(repo, "/", 2)
				if len(parts) != 2 || parts[0] == "" || parts[1] == "" {
					return fmt.Errorf("invalid repo format %q: expected owner/name", repo)
				}
				owner, name := parts[0], parts[1]

				prs, err := listOpenPRsPendingReview(cliCtx, client, owner, name, myLogin)
				if err != nil {
					pterm.Warning.Printfln("failed to list PRs for %s: %v", repo, err)
					continue
				}

				for _, pr := range prs {
					reviews, err := listAllReviews(cliCtx, client, owner, name, pr.GetNumber())
					if err != nil {
						pterm.Warning.Printfln("failed to list reviews for %s#%d: %v", repo, pr.GetNumber(), err)
						continue
					}

					commits, err := listAllCommits(cliCtx, client, owner, name, pr.GetNumber())
					if err != nil {
						pterm.Warning.Printfln("failed to list commits for %s#%d: %v", repo, pr.GetNumber(), err)
						continue
					}

					optional, notes := checkOptional(pr, reviews, commits, myLogin)
					results = append(results, prResult{
						repo:     repo,
						pr:       pr,
						optional: optional,
						notes:    notes,
					})
				}
			}

			if len(results) == 0 {
				pterm.Success.Println("No pull requests pending your review.")
				return nil
			}

			// Sort: required first, then optional; within each group sort by repo then PR number.
			sort.Slice(results, func(i, j int) bool {
				if results[i].optional != results[j].optional {
					return !results[i].optional // required (false) sorts before optional (true)
				}
				if results[i].repo != results[j].repo {
					return results[i].repo < results[j].repo
				}
				return results[i].pr.GetNumber() < results[j].pr.GetNumber()
			})

			return renderTable(results)
		},
	}
	return app.Run(context.Background(), args)
}

// listOpenPRsPendingReview returns all open PRs in owner/repo where myLogin
// appears in the requested reviewers list.
func listOpenPRsPendingReview(ctx context.Context, client *github.Client, owner, repo, myLogin string) ([]*github.PullRequest, error) {
	var result []*github.PullRequest

	opts := &github.PullRequestListOptions{
		State: "open",
		ListOptions: github.ListOptions{
			PerPage: 100,
		},
	}

	for {
		prs, resp, err := client.PullRequests.List(ctx, owner, repo, opts)
		if err != nil {
			return nil, err
		}

		for _, pr := range prs {
			for _, reviewer := range pr.RequestedReviewers {
				if reviewer.GetLogin() == myLogin {
					result = append(result, pr)
					break
				}
			}
		}

		if resp.NextPage == 0 {
			break
		}
		opts.Page = resp.NextPage
	}

	return result, nil
}

// listAllReviews returns every review submitted on the given PR (paginated).
func listAllReviews(ctx context.Context, client *github.Client, owner, repo string, prNumber int) ([]*github.PullRequestReview, error) {
	var result []*github.PullRequestReview

	opts := &github.ListOptions{PerPage: 100}

	for {
		reviews, resp, err := client.PullRequests.ListReviews(ctx, owner, repo, prNumber, opts)
		if err != nil {
			return nil, err
		}
		result = append(result, reviews...)

		if resp.NextPage == 0 {
			break
		}
		opts.Page = resp.NextPage
	}

	return result, nil
}

// listAllCommits returns every commit on the given PR (paginated).
func listAllCommits(ctx context.Context, client *github.Client, owner, repo string, prNumber int) ([]*github.RepositoryCommit, error) {
	var result []*github.RepositoryCommit

	opts := &github.ListOptions{PerPage: 100}

	for {
		commits, resp, err := client.PullRequests.ListCommits(ctx, owner, repo, prNumber, opts)
		if err != nil {
			return nil, err
		}
		result = append(result, commits...)

		if resp.NextPage == 0 {
			break
		}
		opts.Page = resp.NextPage
	}

	return result, nil
}

// checkOptional decides whether a review is optional.
//
// A PR is optional when:
//  1. At least one reviewer (not myLogin, not the PR author) has submitted a
//     substantive review (APPROVED, CHANGES_REQUESTED, or COMMENTED), AND
//  2. No commits have been pushed to the branch after that review.
func checkOptional(pr *github.PullRequest, reviews []*github.PullRequestReview, commits []*github.RepositoryCommit, myLogin string) (bool, string) {
	authorLogin := pr.GetUser().GetLogin()

	// Find the most recent substantive review by a third party.
	var latestReview *github.PullRequestReview
	for _, review := range reviews {
		state := review.GetState()
		if state != "APPROVED" && state != "CHANGES_REQUESTED" && state != "COMMENTED" {
			continue
		}
		login := review.GetUser().GetLogin()
		if login == myLogin || login == authorLogin {
			continue
		}
		if latestReview == nil || review.GetSubmittedAt().Time.After(latestReview.GetSubmittedAt().Time) {
			latestReview = review
		}
	}

	if latestReview == nil {
		// No qualifying third-party review exists; review is required.
		return false, ""
	}

	// Find the most recent commit's committer date.
	var latestCommitTime time.Time
	for _, commit := range commits {
		if commit.Commit == nil || commit.Commit.Committer == nil {
			continue
		}
		t := commit.Commit.Committer.GetDate().Time
		if t.After(latestCommitTime) {
			latestCommitTime = t
		}
	}

	reviewTime := latestReview.GetSubmittedAt().Time

	// Optional when the review is newer than (or equal to) the latest commit.
	if latestCommitTime.IsZero() || !latestCommitTime.After(reviewTime) {
		reviewer := latestReview.GetUser().GetLogin()
		return true, fmt.Sprintf("reviewed by %s, no new commits since", reviewer)
	}

	// A newer commit was pushed after the review — review is required.
	return false, ""
}

// renderTable outputs the results as a pterm table.
func renderTable(results []prResult) error {
	tableData := pterm.TableData{
		{"Status", "Repo", "PR", "Author", "Age", "Title", "Notes"},
	}

	now := time.Now()

	for _, r := range results {
		var status string
		if r.optional {
			status = pterm.FgYellow.Sprint("optional")
		} else {
			status = pterm.FgRed.Sprint("required")
		}

		prNum := fmt.Sprintf("#%d", r.pr.GetNumber())
		author := r.pr.GetUser().GetLogin()
		age := formatAge(now.Sub(r.pr.GetCreatedAt().Time))

		title := r.pr.GetTitle()
		runes := []rune(title)
		if len(runes) > 60 {
			title = string(runes[:57]) + "..."
		}

		tableData = append(tableData, []string{
			status,
			r.repo,
			prNum,
			author,
			age,
			title,
			r.notes,
		})
	}

	return pterm.DefaultTable.WithHasHeader().WithData(tableData).Render()
}

// formatAge returns a human-readable age string for the given duration.
func formatAge(d time.Duration) string {
	switch {
	case d < time.Hour:
		return fmt.Sprintf("%dm", int(d.Minutes()))
	case d < 24*time.Hour:
		return fmt.Sprintf("%dh", int(d.Hours()))
	default:
		return fmt.Sprintf("%dd", int(d.Hours()/24))
	}
}
